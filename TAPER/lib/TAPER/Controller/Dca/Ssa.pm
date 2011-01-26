package TAPER::Controller::Dca::Ssa;

use strict;
use warnings;
use parent 'Catalyst::Controller::HTML::FormFu';

use English;
use XML::LibXML;
use Scalar::Util qw(blessed);
use TAPER::Logic::AuditStamp;

__PACKAGE__->config->{namespace} = 'dca';

use Readonly;
Readonly my $XMLS_NS =>'http://www.w3.org/2001/XMLSchema-instance';

sub ssas : Chained('dca') CaptureArgs(0) {
}

sub ssa : Chained('ssas') CaptureArgs(1) {
    my $self = shift;
    my ( $c, $ssa_id ) = @_;

    my $parser = XML::LibXML->new;
    
    my $ssa = $c->model( 'SSA' )->find( $ssa_id );
    $c->stash->{ssa} = $ssa;
}


sub list : Chained('ssas') Args(0) {
    my $self = shift;
    my ( $c ) = @_;
    
    my $model = $c->model( 'TAPERDB::Office' );
    $c->stash->{offices} = [ $model->search( undef, { order_by => 'name' } ) ];

    $c->stash->{template} = 'dca/ssa/list.tt';
}

sub edit : Chained('ssa') FormConfig('dca/ssa.yml') {
    my $self = shift;
    my ( $c ) = @_;

    my $form = $c->stash->{form};

    $c->forward( 'populate_office_menu' );

    # Little cheat: Change the name of the submit button.
    my $submit_button = $form->get_field( { name => 'ssa_submit' } );
    $submit_button->value( 'Update this Transfer Template' );

    $c->stash->{template} = 'dca/ssa/edit.tt';
}

sub edit_FORM_SUBMITTED {
    my $self = shift;
    my ( $c ) = @_;

    $c->forward( 'validate' );
}

sub edit_FORM_VALID {
    my $self = shift;
    my ( $c ) = @_;

    my $form = $c->stash->{form};
    my $ssa  = $c->stash->{ssa};

    # First, add an <edited> element to the SSA audit trail.
    my $edit = TAPER::Logic::AuditStamp->new( {
	by => $c->taper_user->username,
	timestamp => DateTime->now,
    } );
    $ssa->add_edit( $edit );

    # Now have it update itself.
    $ssa->update_from_form( $form );
}

sub edit_FORM_NOT_SUBMITTED {
    my $self = shift;
    my ( $c ) = @_;

    my $form = $c->stash->{form};
    my $ssa  = $c->stash->{ssa};

    # Fill out the form with existing values.
    $ssa->populate_form( $form );
}

sub create : Chained('ssas') FormConfig('dca/ssa.yml') {
    my $self = shift;
    my ( $c ) = @_;

    my $form = $c->stash->{form};

    $form->default_values({
            warrantToCollect => 'Tufts University Records Policy',
            retentionPeriod => 'Permanent',
            archivalDescriptionStandard => 'DACS',
        });

    $c->forward( 'populate_office_menu' );

    $c->stash->{template} = 'dca/ssa/create.tt';
}

sub create_FORM_SUBMITTED {
    my $self = shift;
    my ( $c ) = @_;

    $c->forward( 'validate' );
}

sub create_FORM_VALID {
    my $self = shift;
    my ( $c ) = @_;

    my $form = $c->stash->{form};

    $c->model( 'SSA' )->create_from_form( $form );

    # Kick the user back to the SSA list page.
    $c->flash->{creation_was_successful} = 1;
    $c->res->redirect( $c->uri_for( '/dca/ssas/list' ) );
}

sub populate_office_menu : Private {
    my $self = shift;
    my ( $c ) = @_;

    my $form = $c->stash->{form};

    my $office_menu = $form->get_element( { name => 'office_id' } );

    my $model = $c->model( 'TAPERDB::Office' );
    my @offices = $model->search( undef, { order_by => 'name' } );
    my @office_options;
    for my $office ( @offices ) {
        push @office_options, [ $office->id, $office->name ];
    }

    $office_menu->options( \@office_options );
}

sub validate : Private {
    my $self = shift;
    my ( $c ) = @_;

    $c->forward( '/validate_producers',
		 [ qw( recordsCreator recordsProducer ) ] );
    $c->forward( '/validate_nonempty_repeatable',
		 [ qw( copyright access ) ] );
}

1;

=head1 NAME

TAPER::Controller::Dca::Ssa

=head1 DESCRIPTION

Catalyst controller for the friendly RSA (regular submission
agreement) creation tool that's usable by the larger Tufts community.

=head1 ACTIONS

=head2 Public Actions

The following documention describes, for each action, not just the
logic this module supplies, but a description of forms and other
information shown to the user via the associated TT templates and
FormFu forms.

=over

=item ssas

Path: dca/ssas/...

Chain root. No logic applied here.

=item list

Path: dca/ssas/list

Displays a hyperlinked list of all the SSAs known to TAPER.

=item create
=item create_FORM_SUBMITTED
=item create_FORM_VALID

Path: dca/ssas/create

Displays and handles the form that allows DCA staff to create new SSA
documents.

=item ssa

Path: dca/ssas/ssa/$ssa_id/...

Chain part. Captures an SSA id, fetches the corresponding SSA object,
and stores it in the stash before passing control along.

=item edit
=item edit_FORM_SUBMITTED
=item edit_FORM_VALID
=item edit_FORM_NOT_SUBMITTED

Path: dca/ssas/ssa/$ssa_id/edit

Displays and handles a form that allows DCA staff to edit an SSA.

=back

=head2 Private Actions

There's probably never need to call these actions directly.

=over

=item populate_office_menu

Populates the current form's "office" pull-down menu with all the
Tufts offices registered with TAPER.

=item validate

Private helper action for validating a submitted SSA form. 

=back

=head1 AUTHOR

Jason McIntosh, Appleseed Software Consulting <jmac@appleseed-sc.com>
Doug Orleans, Appleseed Software Consulting <dougo@appleseed-sc.com>

=head1 COPYRIGHT

Copyright (c) 2009-2010 by Tufts University.

=cut
