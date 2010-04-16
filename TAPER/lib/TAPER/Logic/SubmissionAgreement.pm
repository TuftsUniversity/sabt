package TAPER::Logic::SubmissionAgreement;

use warnings;
use strict;
use English;
use Moose;
use Moose::Util::TypeConstraints;
use Carp qw( croak );
use Scalar::Util;
use List::MoreUtils qw( none each_array );
use TAPER::Logic::Producer;


subtype 'ArrayRefOfStrs' => as 'ArrayRef[Str]';

subtype 'DateTime'
          => as 'Object'
          => where { $_->isa('DateTime') };

subtype 'ArrayRefOfDateTimes' => as 'ArrayRef[DateTime]';

subtype 'URI'
          => as 'Object'
          => where { $_->isa('URI') };

subtype 'Audit'
          => as 'Object'
          => where { $_->isa('TAPER::Logic::AuditStamp') };

subtype 'Producer'
          => as 'Object'
          => where { $_->isa('TAPER::Logic::Producer') };


sub _coerce_date {
    my ( $year, $month, $day) = m{^(....)-(..)-(..)$};
    DateTime->new(
	year  => $year,
	month => $month,
	day   => $day,
    );
}

coerce 'DateTime'
          => from 'Str'
          => via { _coerce_date };

coerce 'ArrayRefOfDateTimes'
          => from 'ArrayRefOfStrs'
          => via { [ map { _coerce_date } @$_ ] };

coerce 'URI'
          => from 'Str'
          => via { URI->new( $_ ) };

use Readonly;
Readonly my $XMLS_NS   =>'http://www.w3.org/2001/XMLSchema-instance';

# History

has 'activation'                 => ( is => 'rw', isa => 'DateTime',
                                      required => 0, coerce => 1 );
has 'producerEndorsement'        => ( is => 'rw', isa => 'DateTime',
                                      required => 0, coerce => 1, );
has 'archiveEndorsement'         => ( is => 'rw', isa => 'DateTime',
                                      required => 0, coerce => 1 );
has 'expiration'                 => ( is => 'rw', isa => 'DateTime',
                                      required => 0, coerce => 1 );

# Audit

has 'created'                    => ( is => 'rw', isa => 'Audit',
                                      required => 0, coerce => 0 );
has 'edited'                     => ( is => 'rw', isa => 'ArrayRef[Audit]',
                                      required => 0, coerce => 0 );
has 'committed'                  => ( is => 'rw', isa => 'Audit',
                                      required => 0, coerce => 0 );

# Archive

has 'archiveId'                  => ( is => 'rw', isa => 'Str',
                                      required => 1 );
has 'warrantToCollect'           => ( is => 'rw', isa => 'ArrayRef',
                                      required => 0 );

# Ingest Project Management

has 'activityLogNumber'          => ( is => 'rw', isa => 'ArrayRef',
                                      required => 0 );
has 'surveyReportId'             => ( is => 'rw', isa => 'ArrayRef',
                                      required => 0 );

# Producer

has 'recordsCreator'             => ( is => 'rw',
                                      isa =>
                                          'ArrayRef[Producer]',
                                      required => 1 );
has 'recordsProducer'            => ( is => 'rw',
                                      isa =>
                                          'ArrayRef[Producer]',
                                      required => 1 );
has 'recordkeepingSystem'        => ( is => 'rw', isa => 'ArrayRef',
                                      required => 0 );

# Records

has 'generalRecordsDescription'  => ( is => 'rw', isa => 'Str',
                                      required => 0 );
has 'recordType'                 => ( is => 'rw', isa => 'Str',
                                      required => 1 );
has 'formatType'                 => ( is => 'rw', isa => 'ArrayRef',
                                      required => 0 );
has 'copyright'                  => ( is => 'rw', isa => 'ArrayRef',
                                      required => 1 );
has 'access'                     => ( is => 'rw', isa => 'ArrayRef',
                                      required => 1 );
has 'arrangementAndNamingScheme' => ( is => 'rw', isa => 'ArrayRef',
                                      required => 0 );
has 'retentionPeriod'            => ( is => 'rw', isa => 'ArrayRef',
                                      required => 0 );
has 'retentionAlertDate'         => ( is => 'rw', isa => 'ArrayRefOfDateTimes',
                                      required => 0, coerce => 1 );

# Producer to Archive

has 'dropboxUrl'                 => ( is => 'rw', isa => 'URI',
                                      required => 1, coerce => 1 );

# Archival Management

has 'archivalDescriptionStandard' => ( is => 'rw', isa => 'ArrayRef',
                                      required => 0 );
has 'respectDeFonds'             => ( is => 'rw', isa => 'ArrayRef',
                                      required => 0 );

sub inherited_fields {
    my $self = shift;

    my %fields;

    # All fields except the Audit fields are inherited from SSA to RSA.
    for my $field_name ( qw(
			     activation
			     producerEndorsement
			     archiveEndorsement
			     expiration
			     archiveId
			     warrantToCollect
			     activityLogNumber
			     surveyReportId
			     recordsCreator
			     recordsProducer
			     recordkeepingSystem
			     generalRecordsDescription
			     recordType
			     formatType
			     copyright
			     access
			     arrangementAndNamingScheme
			     retentionPeriod
			     retentionAlertDate
			     dropboxUrl
			     archivalDescriptionStandard
			     respectDeFonds
                           ) ) {
	if ( defined $self->$field_name ) {
	    $fields{ $field_name } = $self->$field_name;
	}
    }
    return %fields;
}

sub fields_from_form {
    my $class = shift;
    my ( $form ) = @_;

    my %fields;

    # Fields that map to arrayrefs...
    for my $field_name ( qw ( copyright access
                              arrangementAndNamingScheme retentionPeriod
                              retentionAlertDate
                              warrantToCollect activityLogNumber
                              surveyReportId recordkeepingSystem
                              formatType archivalDescriptionStandard
                              respectDeFonds 
                        ) ) {
        my @values = $form->param_list( $field_name );
        if ( scalar @values ) {
            $fields{ $field_name } = \@values;
        }
    }

    # Fields that map to strings...
    for my $field_name ( qw (
                                generalRecordsDescription
                                archiveEndorsement activation expiration
                                recordType dropboxUrl
                        ) ) {
        my $value = $form->param_value( $field_name );
        if ( defined $value ) {
	    $fields{ $field_name } = $value;
        }
    }

    # Handle records creator / producer records
    for my $field_name ( qw (
                                recordsCreator recordsProducer
                        ) ) {
        my @ids    = $form->param_list( "${field_name}_id" );
	my @emails = $form->param_list( "${field_name}_email" );
	my @names  = $form->param_list( "${field_name}_name" );
	my $ea = each_array( @ids, @emails, @names );
	my @producers;
	while ( my ( $id, $email, $name ) = $ea->() ) {
	    my %fields;
	    $fields{id}    = $id    if defined $id    && $id ne '';
	    $fields{email} = $email if defined $email && $email ne '';
	    $fields{name}  = $name  if defined $name  && $name ne '';
	    push @producers, TAPER::Logic::Producer->new( %fields );
	}
	if ( @producers ) {
	    $fields{ $field_name } = \@producers;
	}
    }

    return %fields;
}

sub populate_form {
    my $self = shift;
    my ( $form ) = @_;

    my %default_values;
    for my $field_name ( qw(
			       warrantToCollect activityLogNumber
			       surveyReportId recordkeepingSystem
			       formatType copyright
			       generalRecordsDescription
			       arrangementAndNamingScheme retentionPeriod
			       archiveEndorsement activation expiration
			       recordType access dropboxUrl
			       archivalDescriptionStandard
			       respectDeFonds retentionAlertDate
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
	    my $rep = $form->get_all_element( $field_name );
	    if ( defined $rep ) {
		if ( $rep->can( 'repeat' ) ) {
		    $rep->repeat( $count );

		    # repeat makes a clone of the repeated elements as
		    # they were *before* they were processed, so the
		    # clones may now need to be processed.  Specifically,
		    # Date fields, i.e. retentionAlertDate, need to be
		    # processed in order to populate their components.
		    $rep->process;
		}

		$default_values{ $field_name } = \@values;
	    }
	}
	else {
	    $default_values{ $field_name } = $values[0];
	}

	# If the field has a list of values to select from, add the
	# current values to the selection list.
	my $field = $form->get_field( $field_name );
	if ( defined $field && $field->can( 'options' ) ) {
	    my @options = @{ $field->options };
	    my @new_options;
	    for my $value ( grep { $_ } @values ) {
		if ( none { $_->{value} eq $value } @options ) {
		    push @new_options, [ $value, ucfirst $value ];
		}
	    }
	    $field->options( [ @options, @new_options ] );
	}
    }

    # Records producer / creator fields get special handling.
    for my $field_name ( qw( recordsProducer recordsCreator ) ) {
	my @producers = @{ $self->$field_name };

	my $rep = $form->get_all_element( $field_name );
	if ( defined $rep ) {
	    $rep->repeat( scalar @producers );
	    $default_values{ "${field_name}_id" } =
		[ map { $_->id } @producers ];
	    $default_values{ "${field_name}_email" } =
		[ map { $_->email } @producers ];
	    $default_values{ "${field_name}_name" } =
		[ map { $_->name } @producers ];
	}
    }
    
    $form->default_values( \%default_values );
}

sub fields_from_xml {
    my $class = shift;
    my ( $doc ) = @_;

    my %fields;

    # NOTE: Due to the magic of coercion, object attributes that end up
    # as Datetime objects are just treated as strings during construction.
    # We can pass em in just as they're found in the document.
    
    # Fields that map to arrayrefs...
    for my $field_name ( qw (
                                copyright access
                                arrangementAndNamingScheme retentionPeriod
                                retentionAlertDate
                                warrantToCollect activityLogNumber
                                surveyReportId recordkeepingSystem
                                formatType archivalDescriptionStandard
                                respectDeFonds 
                        ) ) {
        my @values = map {
            $_->to_literal;
        } $doc->findnodes( "//$field_name" );
        if ( @values ) {
            $fields{ $field_name } = \@values;
        }
    }

    # Fields that map to strings...
    for my $field_name ( qw (
                                archiveId generalRecordsDescription
                                archiveEndorsement activation expiration
                                recordType dropboxUrl
                                producerEndorsement
                        ) ) {
        my @values = map {
            $_->to_literal;
        } $doc->findnodes( "//$field_name" );
        if ( @values ) {
            $fields{ $field_name } = $values[0];
        }
    }

    # Hadle the audit elements, which are structured differently.
    for my $field_name ( qw (
                                created committed
                        ) ) {
        my @elements = $doc->findnodes( "//$field_name" );
        if ( @elements ) {
	    my $elt = $elements[0];
            my $stamp = TAPER::Logic::AuditStamp->new( {
                by => $elt->getAttribute( 'by' ),
                timestamp => $elt->getAttribute( 'date' ),
            } );
            $fields{ $field_name } = $stamp;
        }
    }
    if ( my @edits = $doc->findnodes( '//edited' ) ) {
        my @edit_args;
        foreach ( @edits ) {
            my $stamp = TAPER::Logic::AuditStamp->new( {
                by => $_->getAttribute( 'by' ),
                timestamp => $_->getAttribute( 'date' ),
            } );
            push @edit_args, $stamp;
        }
        $fields{ edited } = \@edit_args;
    }

    # And creator / producer records...
    for my $field_name ( qw (
                                recordsCreator recordsProducer
                        ) ) {
        my @elements = $doc->findnodes( "//$field_name" );
        my @producers;
        foreach ( @elements ) {
            my %producer_creation_args;
            if ( defined $_->getAttribute( 'id' ) ) {
                $producer_creation_args{ id } = $_->getAttribute( 'id' );
            }
            if ( defined $_->getAttribute( 'email' ) ) {
                $producer_creation_args{ email } = $_->getAttribute( 'email' );
            }
            if ( defined $_->to_literal ) {
                $producer_creation_args{ name } = $_->to_literal;
            }
            my $producer =
                TAPER::Logic::Producer->new( \%producer_creation_args );
            push @producers, $producer;
        }
        $fields{ $field_name } = \@producers;
    }
    
    return %fields;
}

sub _append_text_children_to_element {
    my $self = shift;
    my ( $element, $kids_ref ) = @_;

    for my $field ( @$kids_ref ) {
        my $method = "$field";
        my $value = $self->$method;
        if ( defined $value ) {
            my @values;
            if ( (ref $value) && (ref $value eq 'ARRAY') ) {
                # Filter out empty lists
                @values = grep { $_ } @$value;
            }
            else {
                @values = ( $value );
            }
            foreach ( @values ) {
		if ( blessed( $_ ) && $_->isa( 'DateTime' ) ) {
		    $_ = $_->ymd;
		}
                $element->appendTextChild( $field => $_ );
            }
        }
    }
}

sub _append_audit_children_to_element {
    my $self = shift;
    my ( $element, $kids_ref ) = @_;

    for my $field ( @$kids_ref ) {
        my $method = "$field";
        my $value = $self->$method;
        if ( defined $value ) {
            my @audit_stamps;
            if ( (ref $value) && (ref $value eq 'ARRAY') ) {
                # Filter out empty lists
                @audit_stamps = grep { $_ } @$value;
            }
            else {
                @audit_stamps = ( $value );
            }
            foreach ( @audit_stamps ) {
                my $child = XML::LibXML::Element->new( $field );
                $child->setAttribute( date => $_->timestamp->ymd );
                $child->setAttribute( by   => $_->by );
                $element->appendChild( $child );
            }
        }
    }
}

sub _append_history_to_root {
    my $self = shift;
    my ( $root ) = @_;

    my $history = XML::LibXML::Element->new( 'history' );
    my $audit   = XML::LibXML::Element->new( 'audit' );

    my @history_kids = ( qw( activation producerEndorsement
                             archiveEndorsement expiration ) );

    $self->_append_text_children_to_element( $history, \@history_kids );

    my @audit_kids = ( qw( created edited committed ) );

    $self->_append_audit_children_to_element( $audit, \@audit_kids );

    $history->appendChild( $audit );
    $root->appendChild( $history);
}

sub _append_producers_to_root {
    my $self = shift;
    my ( $root ) = @_;

    for my $field ( qw( recordsCreator recordsProducer ) ) {
        for my $producer ( @{ $self->$field } ) {
            my $child = XML::LibXML::Element->new( $field );
            if ( defined $producer->id ) {
                $child->setAttribute( id => $producer->id );
            }
            if ( defined $producer->email ) {
                $child->setAttribute( email => $producer->email );
            }
            if ( defined $producer->name ) {
                $child->appendTextNode( $producer->name );
            }
            $root->appendChild( $child );
        }
    }
}

sub add_edit {
    my $self = shift;
    my ( $new_edit ) = @_;
    
    my $edits_ref = $self->edited;
    push @$edits_ref, $new_edit;

    $self->edited( $edits_ref );
}

sub create_document {
    my $self = shift;
    my ( $document_element_name, $schema_location ) = @_;

    my $doc = XML::LibXML::Document->new;
    my $root = XML::LibXML::Element->new( $document_element_name );

    $doc->setDocumentElement( $root );
    $root->setNamespace(
        $XMLS_NS,
        'xsd',
        0,
    );
    $root->setAttributeNS(
        $XMLS_NS,
        'noNamespaceSchemaLocation',
	$schema_location
    );

    # This should correspond to the version attribute on the
    # xsd:schema document element of the SSA/RSA schemas.
    $root->setAttribute(
	'schemaVersion',
	'1.0'
    );

    return $doc;
}

1;

=head1 NAME

TAPER::Logic::SubmissionAgreement - Base class for SA objects

=head1 DESCRIPTION

This is a base class that both TAPER::Logic::SSA and TAPER::Logic::RSA
inherit from. (See also, see also.)

You probably lack sufficient reason to invoke this class directly, but the methods documented here also work on its subclasses.

=head1 METHODS

=head2 Constructor

=over

=item new ( $construction_args_ref )

Class method. A typical Moose-style constructor. See also.

=back

=head2 Accessors

All these are called in the typical Perlish way. Each always returns
the object's current value for the like-named attribute, and if you
pass it an argument, it sets that attribute's value first.

They have studly-capped names in order to match the case used in the
underlying XML files. Sorry about that.

=over

=item archiveEndorsement

=item activation

=item expiration

=item producerEndorsement

Each of these returns a DateTime object. (See L<DateTime>.)

When called as a mutator, the argument can be either a datetime object
or a string of the format 'YYYY-MM-DD'.

=item retentionAlertDate

Returns, and accepts, a reference to an array of DateTime objects.
Also accepts an arrayref of date strings of the format 'YYYY-MM-DD'.

=item created

=item committed

Returns, and accepts, a TAPER::Logic:AuditStamp object.

=item edited

Returns, and accepts, an reference to an array of TAPER::Logic:AuditStamp objects.

=item archiveId

=item generalRecordsDescription

=item recordType

Accepts and returns a string.

=item recordsProducer

=item recordsCreator

Accepts and returns a reference to an array of TAPER::Logic::Producer objects.

=item dropboxUrl

Returns a URI object (see L<URI>). Accepts a URI object, or a URI string.

=item copyright

=item access

=item arrangementAndNamingScheme

=item retentionPeriod

=item warrantToCollect

=item activityLogNumber

=item surveyReportId

=item recordkeepingSystem

=item formatType

=item archivalDescriptionStandard

=item respectDeFonds

Returns and accepts an arrayref of strings.

=back

=head2 Other methods

=over

=item inherited_fields

Returns a hash of field names and values that are inherited from SSA to RSA.

=item fields_from_form ( $form )

This class method returns a hash of field names and values from the
given HTML::FormFu form object.

=item populate_form ( $form )

Sets the default values of the fields of the given HTML::FormFu form
object based on the SubmissionAgreement object's field values.

=item fields_from_xml ( $doc )

This class method returns a hash of field names and values from the
given XML document.

=item add_edit ( $edit_timestamp )

Adds the argument, a TAPER::Logic::AuditStamp object, to this object's
list of edits.

To fetch the full list of edits, use the C<edits()> method.

=item create_document ( $document_element_name, $schema_location )

Used internally to create and initialize a new XML document object
with the given document element name and schema location.

=back

=head1 AUTHOR

Jason McIntosh, Appleseed Software Consulting <jmac@appleseed-sc.com>

=head1 COPYRIGHT

Copyright (c) 2009 by Tufts University.

=cut
