package TAPER::Logic::SSA;

use warnings;
use strict;
use English;
use Moose;
use Moose::Util::TypeConstraints;
use Carp qw( croak );
use Scalar::Util;
use XML::LibXML;

my $parser = XML::LibXML->new;

extends ( 'TAPER::Logic::SubmissionAgreement' );

subtype 'SSADBRow'
          => as 'Object'
          => where { $_->isa('TAPER::Model::TAPERDB::Ssa') };

use Readonly;
Readonly my $ID_PREFIX => 'ssa';

has 'db_record'                  => ( is => 'rw', isa => 'SSADBRow' );

sub id {
    my $self = shift;

    return $self->db_record->id;
}

sub new_from_record {
    my $class = shift;
    my ( $ssa_record ) = @_;

    my $ssa_doc = $parser->parse_file( $ssa_record->absolute_path );
    
    my %ssa_creation_args = $class->fields_from_xml( $ssa_doc );

    $ssa_creation_args{db_record} = $ssa_record;

    my $ssa_object = $class->new( \%ssa_creation_args );

    return $ssa_object;
}

sub update {
    my $self = shift;

    my $ssa_record = $self->db_record;
    # Start knitting up the SSA document.
    my $ssa_doc = $self->create_document(
        'standingSubmissionAgreement', 'ssa.xsd'
    );
    my $root = $ssa_doc->getDocumentElement;

    # Commence pouring in the real data.
    # The submission agreement's structure is mostly flat, so we can
    # get away with much of this with a simple loop.

    # First, we need to take care of the more complex <history> and
    # <audit> elements.

    $self->_append_history_to_root( $root );

    $self->_append_text_children_to_element(
        $root,
        [ qw( archiveId warrantToCollect activityLogNumber surveyReportId ) ],
    );

    $self->_append_producers_to_root( $root );
    
    $self->_append_text_children_to_element(
        $root,
        [ qw (
                 recordkeepingSystem
                 generalRecordsDescription
                 activation expiration
                 recordType formatType copyright access
                 arrangementAndNamingScheme
                 retentionPeriod
                 retentionAlertDate
                 dropboxUrl
                 archivalDescriptionStandard
                 respectDeFonds
         ) ],
    );

    # Set the XML document's id attribute to the new database record's
    # id column value.
    my $ssa_id = $ssa_record->id;
    $root->setAttribute( id => "$ID_PREFIX-$ssa_id" );

    my $ssa_path = $ssa_record->absolute_path;
    
    # Open a filehandle, and write the SSA file.
    open my $ssa_handle, '>', $ssa_path
        or die "Can't write to $ssa_path: $OS_ERROR";
    print $ssa_handle $ssa_doc->toString( 1 );
    close $ssa_handle;

    $ssa_record->update;
}

sub update_from_form {
    my $self = shift;
    my ( $form ) = @_;

    # Sanity check...
    unless ( $form ) {
        croak ('update_from_form() called with too few arguments');
    }

    my %fields = $self->fields_from_form( $form );

    # TO DO: make an office_id setter
    $self->db_record->office( delete $fields{office_id} );

    while ( my ( $field_name, $value ) = each %fields ) {
	$self->$field_name( $value );
    }

    $self->update;
}

sub fields_from_form {
    my $class = shift;
    my ( $form ) = @_;

    my %fields = $class->next::method( @_ );

    $fields{office_id} = $form->param_value( 'office_id' );

    return %fields;
}

sub populate_form {
    my $self = shift;
    my ( $form ) = @_;

    $self->next::method( @_ );

    $form->default_values( { office_id => $self->db_record->office->id } );
}

1;

=head1 NAME

TAPER::Logic::SSA - Business logic class for SSA objects

=head1 DESCRIPTION

Objects of this class represent Standing Submission Agreements. Under
the hood, SSAs exist mostly as XML documents and partly as database
records; this module helps abstract this straddling into a single API.

From within the TAPER application, you'll often want to create one of
these objects by way of TAPER::Model::SSA. See also.

=head1 METHODS

This class extends TAPER::Logic::SubmissionAgreement, and supports all
the methods that it does. See also.

=head2 Accessors

=over

=item db_record ( $db_record )

Returns the object's associated DB record, an object of class
TAPER::Model::TAPERDB::Ssa.

You can change the SSA's associated DB record by passing it one as an
argument to this method. But you probably don't want to do that.

=item id

B<Read-only>. Returns the ID field of this SSA's database record.

=back

=head2 Other methods

=over

=item new_from_record ( $ssa_record )

This class method returns a new SSA object given a database record, an
object of class TAPER::Model::TAPERDB::Ssa.  The new object's fields
are populated from the XML file pointed to by the record object's
absolute_path field.

=item update

Writes out this object to the disk and database. In other words, after you're done making changes to the SSA object, you should call this method.

=item update_from_form ( $form )

Accepts an HTML::FormFu form object, and has the SSA object update
itself based on the field values found therein.

=item fields_from_form ( $form )

This class method returns a hash containing field names and values
from the HTML::FormFu form object.

=item populate_form ( $form )

Sets the default values of the fields of an HTML::FormFu form object
based on the SSA object's field values.

=back

=head1 AUTHOR

Jason McIntosh, Appleseed Software Consulting <jmac@appleseed-sc.com>
Doug Orleans, Appleseed Software Consulting <dougo@appleseed-sc.com>

=head1 COPYRIGHT

Copyright (c) 2009-2010 by Tufts University.

=cut
