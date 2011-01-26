package TAPER::Model::RSA;

use strict;
use warnings;
use parent 'Catalyst::Model';
use TAPER::Logic::RSA;
use Carp qw( croak );
use English;
use File::Path qw( make_path );
use File::Basename qw( basename );
use Archive::Zip;
use IO::String;

__PACKAGE__->mk_accessors( qw(context) );

sub ACCEPT_CONTEXT {
    my ($self, $c, @args) = @_;
    $self->context($c);
    return $self;
}

sub find {
    my $self = shift;
    my ( $id ) = @_;
    
    unless ( defined $id ) {
        croak ('find() called without an RSA ID');
    }
    
    my $c = $self->context;

    my $rsa_record = $c->model( 'TAPERDB::Rsa' )->find( $id );

    unless ( $rsa_record ) {
        croak ( "There is no RSA with ID '$id'." );
    }

    return TAPER::Logic::RSA->new_from_record( $rsa_record );
}

sub drafts {
    return shift->_search( { is_final => 0 } );
}

sub archive {
    return shift->_search( { is_final => 1 } );
}

sub _search {
    my $self = shift;

    my $c = $self->context;

    my @rsa_records = $c->model( 'TAPERDB::Rsa' )->search( @_ );

    return map { TAPER::Logic::RSA->new_from_record( $_ ) } @rsa_records;
}

sub zip {
    my $self = shift;
    my ( @rsas ) = @_;
    
    my $c = $self->context;

    my $zip = Archive::Zip->new;
    for my $rsa ( @rsas ) {
	my $path = $c->model( 'TAPERDB::Rsa' )->find( $rsa )->absolute_path;
	$zip->addFile( $path, basename( $path ) );
    }

    my $fh = IO::String->new;
    $zip->writeToFileHandle( $fh );
    return ${ $fh->string_ref };
}

sub create_from_form {
    my $self = shift;
    my ( $form, $ssa ) = @_;
    my $c = $self->context;

    # Sanity check...
    unless ( $form && $ssa ) {
        croak ('create_from_form() called with too few arguments');
    }

    # Create the database record for this RSA.
    my $rsa_record = $c->model( 'TAPERDB::Rsa' )->create( {
	ssa      => $ssa->id,
	is_final => 0,
    } );

    # Now start preparing the new RSA object.
    my %ssa_fields = $ssa->inherited_fields;
    my %form_fields = TAPER::Logic::RSA->fields_from_form( $form );
    my %rsa_creation_args = ( %ssa_fields, %form_fields );

    $rsa_creation_args{ db_record } = $rsa_record;

    # Make a recordsProducer from the user's LDAP info.
    my $producer = TAPER::Logic::Producer->new_from_user( $c->user );
    $rsa_creation_args{ recordsProducer } = [ $producer ];

    # Generate the timestamp for the producerEndorsement element.
    my $now_dt = DateTime->now;
    $rsa_creation_args{ producerEndorsement } = $now_dt;

    # Create the RSA object!
    my $rsa_object = TAPER::Logic::RSA->new( \%rsa_creation_args );

    my $rsa_id = $rsa_object->id;
    
    # Create the directory for this RSA.
    my $staging_dir = $c->config->{rsa_staging_directory};
    unless ( -e $staging_dir ) {
        unless ( make_path( $staging_dir ) ) {
            die "Can't create staging area directory at $staging_dir: "
                . $OS_ERROR;
        }
    }

    my $rsa_path = File::Spec->catdir(
        $staging_dir,
        $rsa_id,
    );

    my $inventory_path = File::Spec->catdir(
        $rsa_path,
        'inventory',
    );
    
    # The path stored in the database is relative to $staging_dir.
    my $rsa_file_path = File::Spec->catfile(
	$rsa_id,
        "$rsa_id.xml",
    );

    # Create the RSA path, and inventory dir (unless they already exist)
    unless ( -e $rsa_path ) {
        mkdir $rsa_path
            or die "Can't mkdir $rsa_path: $OS_ERROR";
    }
    unless ( -e $inventory_path ) {
        mkdir $inventory_path
            or die "Can't mkdir $inventory_path: $OS_ERROR";
    }

    # Tell the RSA's DB object about its file path
    $rsa_record->path( $rsa_file_path );
    $rsa_record->update;
    
    # Add a <created> element to the RSA's audit trail.
    my $edit = TAPER::Logic::AuditStamp->new( {
	by => $c->taper_user->username,
	timestamp => DateTime->now,
    } );
    $rsa_object->created( $edit );

    # Let the RSA object write itself to its path.
    $rsa_object->update;

    return $rsa_object;
}

=head1 NAME

TAPER::Model::RSA - Catalyst Model for Regular Submission Agreements

=head1 SYNOPSIS

 # Get the RSA with ID 'Foo'
 my $rsa = $c->model( 'RSA' )->find( 'Foo' );

 # Create a new RSA based on the current HTML::FormFu form
 my $rsa = $c->model( 'RSA' )->create_from_form( $form, $ssa );

=head1 DESCRIPTION

This is a catalyst model that simplifies the creation and fetching of objects that represent RSAs.

The objects themselves are instances of TAPER::Logic::RSA (see also).

=head1 METHODS

=over

=item find ( $rsa_id )

If the given string matches the ID of an RSA that TAPER knows about,
then this returns the corresponding TAPER::Logic::RSA object.

Otherwise, returns undef.

=item drafts
=item archive

These two methods return lists of TAPER::Logic::RSA objects
corresponding to all draft and archived RSAs in the database,
respectively.

=item zip ( @rsa_ids )

Returns a string whose contents are a zip file containing the XML
documents for the RSAs with the given ids.

=item create_from_form ( $form, $ssa )

Given an HTML::FormFu form (filled out with RSA information) and a
TAPER::Model::SSA object, creates a new RSA object based on both. This
includes the creation of the RSA's DBIx::Class::Row object
(representing a brand-new RSA in the TAPER database) and XML file.

=back

=head1 NOTES

This module and TAPER::Logic::RSA are almost certainly more
artificially divided than they ought to be, making them hard to
maintain. They're due for some merging and refactoring.

=head1 AUTHOR

Jason McIntosh, Appleseed Software Consulting <jmac@appleseed-sc.com>
Doug Orleans, Appleseed Software Consulting <dougo@appleseed-sc.com>

=head1 COPYRIGHT

Copyright (c) 2009-2010 by Tufts University.

=cut

1;
