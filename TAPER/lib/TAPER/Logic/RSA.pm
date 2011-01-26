package TAPER::Logic::RSA;

use warnings;
use strict;
use English;
use Moose;
use Moose::Util::TypeConstraints;
use Carp qw( croak );
use Scalar::Util;
use List::MoreUtils qw( pairwise each_array );
use TAPER::Logic::Extent;
use TAPER::Logic::DateSpan;
use XML::LibXML;
use File::Basename qw( dirname basename );
use File::Path qw( remove_tree );
use Archive::Zip;
use IO::String;

my $parser = XML::LibXML->new;

extends ( 'TAPER::Logic::SubmissionAgreement');

has 'dateSpan' => ( is => 'rw', isa => 'ArrayRef[TAPER::Logic::DateSpan]', required => 1 );
has 'extent' => ( is => 'rw', isa => 'ArrayRef[TAPER::Logic::Extent]', required => 1 );
has 'accessionNumber'     => ( is => 'rw', isa => 'Str', required => 0 );
has 'sipToAip'         => ( is => 'rw', isa => 'ArrayRef', required => 0 );
has 'sipCreationAndTransfer'     => ( is => 'rw', isa => 'ArrayRef', required => 1 );
has 'transferDate' => ( is => 'rw', isa => 'DateTime', coerce => 1 );

has 'ssa'          => ( is => 'ro', isa => 'TAPER::Logic::SSA', lazy_build => 1);
has 'db_record'    => ( is => 'rw', isa => 'TAPER::Model::TAPERDB::Rsa' );

use Readonly;
Readonly my $ID_PREFIX => 'rsa';

sub new_from_record {
    my $class = shift;
    my ( $rsa_record ) = @_;

    my $rsa_doc = $parser->parse_file( $rsa_record->absolute_path );
    
    my %rsa_creation_args = $class->fields_from_xml( $rsa_doc );

    $rsa_creation_args{db_record} = $rsa_record;

    # NOTE: Due to the magic of coercion, object attributes that end up
    # as Datetime objects are just treated as strings during construction.
    # We can pass em in just as they're found in the document.
    
    # Fields that map to arrayrefs...
    for my $field_name ( qw ( sipCreationAndTransfer sipToAip ) ) {
        my @values = map {
            $_->to_literal;
        } $rsa_doc->findnodes( "//$field_name" );
        if ( @values ) {
            $rsa_creation_args{ $field_name } = \@values;
        }
    }

    # Fields that map to strings...
    for my $field_name ( qw ( accessionNumber transferDate ) ) {
        my @values = map {
            $_->to_literal;
        } $rsa_doc->findnodes( "//$field_name" );
        if ( @values ) {
            $rsa_creation_args{ $field_name } = $values[0];
        }
    }

    # Now deal with the weird stuff.
    # Extents...
    if ( my @extent_nodes = $rsa_doc->findnodes( "//extent" ) ) {
        my @extents;
        foreach ( @extent_nodes ) {
            my $units = $_->findvalue( '@units' );
            my $value = $_->findvalue( '@value' );
            push @extents, TAPER::Logic::Extent->new ( {
                units => $units,
                value => $value,
            } );
        }
        $rsa_creation_args{ extent } = \@extents;
    }

    # Date spans...
    if ( my @datespan_nodes = $rsa_doc->findnodes( "//dateSpan" ) ) {
        my @datespans;
        foreach ( @datespan_nodes ) {
            my $start = $_->findvalue( '@start' );
            my $end   = $_->findvalue( '@end' );
            push @datespans, TAPER::Logic::DateSpan->new ( {
                start => $start,
                end   => $end,
            } );
        }
        $rsa_creation_args{ dateSpan } = \@datespans;
    }

    my $rsa_object = $class->new( \%rsa_creation_args );
    
    return $rsa_object;
}

sub update {
    my $self = shift;

    my $rsa_record = $self->db_record;

    my $rsa_doc = $self->create_document(
	'regularSubmissionAgreement', 'rsa.xsd'
    );
    my $root = $rsa_doc->getDocumentElement;
    
    $self->_append_history_to_root( $root );

    # Add a bunch of simple elements.
    $self->_append_text_children_to_element
        (
            $root,
            [ qw( archiveId warrantToCollect accessionNumber
                  activityLogNumber
                  surveyReportId
            ) ]
        );

    # Records creator/producer...
    $self->_append_producers_to_root( $root );
    
    # More simple elements. Tum te tum.
    $self->_append_text_children_to_element
        (
            $root,
            [ qw (
                     recordkeepingSystem
                     generalRecordsDescription
                     recordType formatType
            ) ]
        );
    
    
    # DateSpans...
    for my $span ( @{ $self->dateSpan } ) {
        my $span_el = XML::LibXML::Element->new( 'dateSpan' );
        $span_el->setAttribute( start => $span->start );
        $span_el->setAttribute( end => $span->end );
        $root->addChild( $span_el );
    }
    
    # Extents...
    for my $extent ( @{ $self->extent } ) {
        my $extent_el = XML::LibXML::Element->new( 'extent' );
        $extent_el->setAttribute( value => $extent->value );
        $extent_el->setAttribute( units => $extent->units );
        $root->addChild( $extent_el );
    }

    $self->_append_text_children_to_element
        (
            $root,
            [ qw( copyright access
                  arrangementAndNamingScheme
                  retentionPeriod
                  retentionAlertDate
                  sipCreationAndTransfer
                  dropboxUrl
                  transferDate
                  sipToAip
                  archivalDescriptionStandard
                  respectDeFonds
            ) ]
        );

    # If the document doesn't have an ID attribute, create one,
    # basing it on the database record's id column value.
    my $rsa_id = $rsa_record->id;
    $root->setAttribute( id => "$ID_PREFIX-$rsa_id" );

    my $rsa_path = $rsa_record->absolute_path;
    
    # Open a filehandle, and write the RSA file.
    open my $rsa_handle, '>', $rsa_path
        or die "Can't write to $rsa_path: $OS_ERROR";
    print $rsa_handle $rsa_doc->toString( 1 );
    close $rsa_handle;

    $rsa_record->update;

    return $self;
}

sub update_from_form {
    my $self = shift;
    my ( $form ) = @_;

    # Sanity check...
    unless ( $form ) {
        croak ('update_from_form() called with too few arguments');
    }

    my %fields = $self->fields_from_form( $form );

    # TO DO: make an is_final setter
    $self->db_record->is_final( delete $fields{is_final} );

    while ( my ( $field_name, $value ) = each %fields ) {
	$self->$field_name( $value );
    }

    $self->update;

    return $self;
}

sub fields_from_form {
    my $class = shift;
    my ( $form ) = @_;

    my %fields = $class->next::method( @_ );

    # The record's draft/final status.
    if ( defined ( my $is_final = $form->param_value( 'is_final' ) ) ) {
	$fields{is_final} = $is_final;
    }

    # Fields that map to arrayrefs...
    for my $field_name ( qw ( sipCreationAndTransfer sipToAip ) ) {
        my @values = $form->param_list( $field_name );
        if ( scalar @values ) {
            $fields{ $field_name } = \@values;
        }
    }

    # Fields that map to strings...
    for my $field_name ( qw ( accessionNumber transferDate ) ) {
        my $value = $form->param_value( $field_name );
        if ( defined $value ) {
            $fields{ $field_name } = $value;
        }
    }

    # DateSpans...
    if ( my @span_starts = $form->param_list( 'dateSpan_start' ) ) {
	my @span_ends = $form->param_list ( 'dateSpan_end' );
	my @spans = pairwise {
	    TAPER::Logic::DateSpan->new( start => $a, end => $b )
	} @span_starts, @span_ends;
	$fields{dateSpan} = \@spans;
    }

    # Extents...
    if ( my @extent_units = $form->param_list( 'extent_units' ) ) {
	my @extent_values = $form->param_list( 'extent_value' );
        my @extent_other = $form->param_list( 'extent_other_units' );
        my $ea = each_array( @extent_units, @extent_values, @extent_other );
        my @extents;
        while ( my ($units, $value, $other) = $ea->() ) {
            if ( $units eq 'other' && $other ne '' ) { $units = $other; }
            push @extents, TAPER::Logic::Extent->new( units => $units,
                                                      value => $value );
	} 
	$fields{extent} = \@extents;
    }

    return %fields;
}

sub populate_form {
    my $self = shift;
    my ( $form ) = @_;

    $self->next::method( @_ );

    my %default_values;
    for my $field_name ( qw(
			       accessionNumber sipToAip
			       sipCreationAndTransfer
			       transferDate
		       ) ) {
	my $value = $self->$field_name;
	my @values;
	if ( ref $value && ref $value eq 'ARRAY' ) {
	    @values = @$value;
	}
	else {
	    @values = ( $value );
	}
	my $count = @values;
	if ( $count > 1 ) {
	    $form->get_all_element( $field_name )->repeat( $count );
	    $default_values{ $field_name } = \@values;
	}
	else {
	    $default_values{ $field_name } = $values[0];
	}
    }

    # Handle the weirdness of datespans and extents.
    my @spans = @{ $self->dateSpan };
    $form->get_all_element( 'dateSpan' )->repeat( scalar @spans );
    $default_values{ dateSpan_start } = [ map { $_->start } @spans ];
    $default_values{ dateSpan_end }   = [ map { $_->end }   @spans ];

    my @extents = @{ $self->extent };
    $form->get_all_element( 'extent' )->repeat( scalar @extents );
    $default_values{ extent_value } = [ map { $_->value } @extents ];
    $default_values{ extent_units } = [ map { $_->units } @extents ];

    # Fill in the is_final field from the DB directly.
    $default_values{ is_final } = $self->db_record->is_final;
    
    $form->default_values( \%default_values );
}

# This is called automatically when the ssa attribute's reader method
# is called (because it has lazy_build = 1).
sub _build_ssa {
    my $self = shift;

    my $ssa_db_record = $self->db_record->ssa;

    return TAPER::Logic::SSA->new_from_record( $ssa_db_record );
}

sub id {
    my $self = shift;

    return $self->db_record->id;
}

sub creator {
    my $self = shift;

    for ( @{ $self->recordsCreator } ) {
	return $_->name if $_->name;
    }
    return $self->ssa->db_record->office->name;
}

sub inventory_documents {
    my $self = shift;

    my $dir = dirname( $self->db_record->absolute_path ) . '/inventory/';
    opendir( my $dh, $dir );
    my @docs = grep { !( /^\.$/ || /^\.\.$/ ) } readdir( $dh );
    closedir( $dh );

    return map { $dir . $_ } @docs;
}

sub inventory_zip {
    my $self = shift;

    my $zip = Archive::Zip->new;
    for my $doc ( $self->inventory_documents ) {
	$zip->addFile( $doc, basename( $doc ) );
    }

    my $fh = IO::String->new;
    $zip->writeToFileHandle( $fh );
    return ${ $fh->string_ref };
}

sub delete {
    my $self = shift;

    remove_tree( dirname( $self->db_record->absolute_path ) );
    $self->db_record->delete;
}

1;

=head1 NAME

TAPER::Logic::RSA - Business logic class for RSA objects

=head1 DESCRIPTION

Objects of this class represent Regular Submission Agreements. Under
the hood, RSAs exist mostly as XML documents and partly as database
records; this module helps abstract this straddling into a single API.

From within the TAPER application, you'll often want to create one of
these objects by way of TAPER::Model::RSA. See also.

=head1 METHODS

This class extends TAPER::Logic::SubmissionAgreement, and supports all
the methods that it does. See also.

=head2 Accessors

These are called in the typical Perlish way. Each always returns
the object's current value for the like-named attribute, and if you
pass it an argument, it sets that attribute's value first.

=over

=item dateSpan

Accepts and returns a reference to an array of TAPER::Logic::DateSpan objects.

=item extent

Accepts and returns a reference to an array of TAPER::Logic::Extent objects.

=item accessionNumber

Accepts and return a string.

=item sipCreationAndTransfer

=item sipToAip

These each accept and return a reference to an array of strings.

=item transferDate

Returns a DateTime object. (See L<DateTime>.)

When called as a mutator, the argument can be either a datetime object
or a string of the format 'YYYY-MM-DD'.

=item id

B<Read-only>. Returns the ID field of this RSA's database record.

=item creator

B<Read-only>. Returns the creator name of this RSA, if any, or else
the office name of its SSA.

=item db_record

Returns the object's associated DB record, an object of class
TAPER::Model::TAPERDB::Rsa.

You can change the RSA's associated DB record by passing it one as an
argument to this method. But you probably don't want to do that.

=item ssa

Returns the object's associated SSA, as a TAPER::Logic::SSA object.

=item inventory_documents

B<Read-only>.  Returns a list of absolute filesystem paths for the
inventory document files for this RSA.

=item inventory_zip

B<Read-only>.  Returns a string containing a zip file containing all
the inventory document files for this RSA.

=back

=head2 Other methods

=over

=item new_from_record ( $rsa_record )

This class method returns a new RSA object given a database record, an
object of class TAPER::Model::TAPERDB::Rsa.  The new object's fields
are populated from the XML file pointed to by the record object's path field.

=item update

Writes out this object to the disk and database. In other words, after you're done making changes to the RSA object, you should call this method.

=item update_from_form ( $form )

Accepts an HTML::FormFu form object, and has the RSA object update
itself based on the field values found therein.

=item fields_from_form ( $form )

This class method returns a hash containing field names and values
from the HTML::FormFu form object.

=item populate_form ( $form )

Sets the default values of the fields of an HTML::FormFu form object
based on the RSA object's field values.

=item delete

Deletes the RSA from the system, including its database record, XML
file, and inventory files.

=back

=head1 AUTHOR

Jason McIntosh, Appleseed Software Consulting <jmac@appleseed-sc.com>
Doug Orleans, Appleseed Software Consulting <dougo@appleseed-sc.com>

=head1 COPYRIGHT

Copyright (c) 2009-2010 by Tufts University.

=cut
