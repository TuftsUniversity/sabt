package TAPER::Controller::Dca::Offices;

use strict;
use warnings;
use parent 'Catalyst::Controller::HTML::FormFu';

sub offices : Chained('../dca') CaptureArgs(0) {
}

sub list : Chained('offices') Args(0) FormConfig('dca/office') {
}

sub list_FORM_VALID {
    my $self = shift;
    my ( $c ) = @_;

    my $form = $c->stash->{form};

    my $name = $form->param_value( 'name' );
    my $office = $c->model( 'TAPERDB::Office' )->create( { name => $name } );
    $c->stash->{office} = $office;

    # Clear the form so it can be used to add another office.
    # This depends on the fields having force_default = 1.
    $form->default_values( { name => '' } );
}

sub office : Chained('offices') CaptureArgs(1) {
    my $self = shift;
    my ( $c, $office_id ) = @_;

    $c->stash->{office} = $c->model( 'TAPERDB::Office' )->find( $office_id );
}

sub edit : Chained('office') Args(0) FormConfig('dca/office') {
}

sub edit_FORM_NOT_SUBMITTED {
    my $self = shift;
    my ( $c ) = @_;

    my $form = $c->stash->{form};
    my $office = $c->stash->{office};

    $form->default_values( { name => $office->name } );
}

sub edit_FORM_VALID {
    my $self = shift;
    my ( $c ) = @_;
    
    my $form = $c->stash->{form};
    my $office = $c->stash->{office};

    $office->name( $form->param_value( 'name' ) );
    $office->update;
}

sub delete : Chained('office') Args(0) {
    my $self = shift;
    my ( $c ) = @_;

    my $office = $c->stash->{office};
    $c->flash->{office} = $office;

    if ( !$office || $office->ssas > 0 ) {
        $c->flash->{office_not_deleted} = 1;
    } else {
        $office->delete;
        $c->flash->{office_deleted} = 1;
    }

    $c->res->redirect( $c->uri_for( '/dca/offices/list' ) );
    $c->detach;
}

1;

=head1 NAME

TAPER::Controller::Dca::Offices

=head1 DESCRIPTION

=head1 ACTIONS

=head2 Public Actions

The following documention describes, for each action, not just the
logic this module supplies, but a description of forms and other
information shown to the user via the associated TT templates and
FormFu forms.

=over

=item offices

Path: dca/offices/...

Chain root.

=item list
=item list_FORM_VALID

Path: dca/offices/list

Displays a hyperlinked list of all the offices known to TAPER, plus a
form for adding a new office.

=item office

Path: dca/offices/office/$office_id/...

Chain part.  Puts the office with the given id into the stash.

=item edit
=item edit_FORM_NOT_SUBMITTED
=item edit_FORM_VALID

Path: dca/offices/office/$office_id/edit

Displays and handles a form that allows DCA staff to edit an office.

=item delete

Path: dca/offices/offices/$office_id/delete

Deletes an office.  The office will not be deleted if it has any
associated SSAs.

=back

=head1 AUTHOR

Doug Orleans, Appleseed Software Consulting <dougo@appleseed-sc.com>

=head1 LICENSE

=head1 COPYRIGHT

Copyright (c) 2009-2010 by Tufts University.

=cut
