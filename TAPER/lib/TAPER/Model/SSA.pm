package TAPER::Model::SSA;

use strict;
use warnings;
use parent 'Catalyst::Model';
use TAPER::Logic::SSA;
use Carp qw( croak );
use English;
use Scalar::Util qw( blessed );
use File::Path qw( make_path );

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
        croak ('find() called without an SSA ID');
    }

    my $c = $self->context;

    my $ssa_record = $c->model( 'TAPERDB::Ssa' )->find( $id );

    unless ( $ssa_record ) {
	croak ( "There is no SSA with ID '$id'." );
    }

    return TAPER::Logic::SSA->new_from_record( $ssa_record );
}

sub all_for_office {
    my $self = shift;
    my ( $office_id ) = @_;

    my $c = $self->context;

    my @ssa_records = $c->model( 'TAPERDB::Ssa' )->search( {
	office => $office_id } );

    return map { TAPER::Logic::SSA->new_from_record( $_ ) } @ssa_records;
}

sub create_from_form {
    my $self = shift;
    my ( $form ) = @_;
    my $c = $self->context;

    # Sanity check...
    unless ( $form ) {
        croak ('create_from_form() called with too few arguments');
    }

    # Figure out this new SSA doc's filesystem path.
    my $ssa_dir = $c->config->{ssa_directory};
    unless ( -e $ssa_dir ) {
	unless ( make_path( $ssa_dir ) ) {
	    die "Can't create SSA directory at $ssa_dir: "
		. $OS_ERROR;
	}
    }

    # Create a new DB record for this SSA.
    my $ssa_record = $c->model( 'TAPERDB::Ssa' )->create( { } );

    my $ssa_path = File::Spec->catdir(
	$ssa_dir,
	$ssa_record->id . '.xml',
    );
    $ssa_record->path( $ssa_path );

    # Now start preparing the new SSA object.
    my %ssa_creation_args = TAPER::Logic::SSA->fields_from_form( $form );
    
    $ssa_record->office( delete $ssa_creation_args{office_id} );

    $ssa_creation_args{ db_record } = $ssa_record;
    $ssa_creation_args{ archiveId } = $c->config->{ archive_id };

    my $ssa_object = TAPER::Logic::SSA->new( \%ssa_creation_args );

    # Add a <created> element to the SSA audit trail.
    my $edit = TAPER::Logic::AuditStamp->new( {
	by => $c->taper_user->username,
	timestamp => DateTime->now,
    } );
    $ssa_object->created( $edit );

    $ssa_object->update;

    return $ssa_object;
}

=head1 NAME

TAPER::Model::SSA - Catalyst Model for Standing Submission Agreements

=head1 SYNOPSIS

 # Get the SSA with ID 'Foo'
 my $ssa = $c->model( 'SSA' )->find( 'Foo' );

 # Create a new SSA based on the current HTML::FormFu form
 my $ssa = $c->model( 'SSA' )->create_from_form( $form );

=head1 DESCRIPTION

This is a catalyst model that simplifies the creation and fetching of objects that represent SSAs.

The objects themselves are instances of TAPER::Logic::SSA (see also).

=head1 METHODS

=over

=item find ( $ssa_id )

If the given string matches the ID of an SSA that TAPER knows about,
then this returns the corresponding TAPER::Logic::SSA object.

Otherwise, returns undef.

=item all_for_office ( $office_id )

Returns a list of TAPER::Logic::SSA objects, one for each SSA in the
database that is associated with the office whose ID is given.

=item create_from_form ( $form )

Given an HTML::FormFu form (filled out with SSA information), creates
a new SSA object. This includes the creation of the SSA's
DBIx::Class::Row object (representing a brand-new SSA in the TAPER
database) and XML file.

=back

=head1 NOTES

This module and TAPER::Logic::SSA are almost certainly more
artificially divided then they ought to be, making them hard to
maintain. They're due for some merging and refactoring.

=head1 AUTHOR

Jason McIntosh, Appleseed Software Consulting <jmac@appleseed-sc.com>

=head1 COPYRIGHT

Copyright (c) 2009 by Tufts University.

=cut


1;
