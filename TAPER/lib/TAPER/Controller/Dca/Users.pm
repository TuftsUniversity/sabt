package TAPER::Controller::Dca::Users;

use strict;
use warnings;
use parent 'Catalyst::Controller::HTML::FormFu';

use List::MoreUtils qw( each_arrayref );
use Set::Scalar;

# An array of scalar field names on the User class.  user_offices is
# handled separately.
my @field_names = qw( username first_name last_name is_dca );

sub users : Chained('../dca') CaptureArgs(0) {
}

sub list : Chained('users') Args(0) {
}

sub add : Chained('users') Args(0) FormConfig('dca/user') {
    my $self = shift;
    my ( $c ) = @_;

    my $form = $c->stash->{form};
    $form->get_field( { type => 'Submit' } )->value( 'Add user' );

    $c->forward( '_populate_office_menu' );
}

sub add_FORM_NOT_SUBMITTED {
    my $self = shift;
    my ( $c ) = @_;

    my $form = $c->stash->{form};
    $form->get_element( 'office' )->repeat( 0 );
}

sub add_FORM_NOT_VALID {
    my $self = shift;
    my ( $c ) = @_;

    $c->forward( '_fix_office_fields' );
}

sub add_FORM_VALID {
    my $self = shift;
    my ( $c ) = @_;

    my $form = $c->stash->{form};

    my %params = map { $_ => $form->param_value( $_ ) } @field_names;
    $c->stash->{user} = $c->model( 'TAPERDB::User' )->create( \%params );

    $c->forward( '_add_offices' );

    $c->flash->{user_added} = 1;
    $c->res->redirect( $c->uri_for( '/dca/users/list' ) );
    $c->detach;
}


sub user : Chained('users') CaptureArgs(1) {
    my $self = shift;
    my ( $c, $user_id ) = @_;

    $c->stash->{user} = $c->model( 'TAPERDB::User' )->find( $user_id );
}

sub edit : Chained('user') Args(0) FormConfig('dca/user') {
    my $self = shift;
    my ( $c ) = @_;

    my $form = $c->stash->{form};
    $form->get_field( { type => 'Submit' } )->value( 'Update user' );

    $c->forward( '_populate_office_menu' );
}

sub edit_FORM_NOT_SUBMITTED {
    my $self = shift;
    my ( $c ) = @_;

    $c->forward( '_populate_user_form' );
}

sub edit_FORM_NOT_VALID {
    my $self = shift;
    my ( $c ) = @_;

    $c->forward( '_fix_office_fields' );

    my $form = $c->stash->{form};
}

sub edit_FORM_VALID {
    my $self = shift;
    my ( $c ) = @_;

    my $form = $c->stash->{form};
    my $user = $c->stash->{user};

    for my $f ( @field_names ) {
	$user->$f( $form->param_value( $f ) );
    }

    $user->user_offices->delete;
    $c->forward( '_add_offices' );

    # Re-display the form using values from the DB.
    $c->forward( '_populate_user_form' );
}


sub _populate_office_menu : Private {
    my $self = shift;
    my ( $c ) = @_;

    my $form = $c->stash->{form};
    my $button = $form->get_all_element( { id => 'add_office_button' } );
    $button->parent->remove_element( $button );


    my $model = $c->model( 'TAPERDB::Office' );
    my @offices = $model->search( undef, { order_by => 'name' } );

    $form->get_all_element( { id => 'office' } )->element(
	{ type => 'Select',
	  id => 'add_office_select',
	  options => [ [ '', 'Add a new office:' ],
		       map { [ $_->id, $_->name ] } @offices ],
	  attrs => { onchange => 'add_office( this )' },
	} );
}

# Set form default values based on user data.
sub _populate_user_form : Private {
    my $self = shift;
    my ( $c ) = @_;

    my $form = $c->stash->{form};
    my $user = $c->stash->{user};

    my @user_offices = $user->user_offices_sorted;
    $form->get_element( 'office' )->repeat( scalar @user_offices );

    my @ids = map { $_->office->id } @user_offices;
    $c->forward( '_set_checkbox_values', \@ids );

    my %values = map { $_ => $user->$_ } @field_names;
    $values{office_id} = [ map { $_->office->id } @user_offices ];
    $values{office_name} = [ map { $_->office->name } @user_offices ];
    $values{office_active} = [ map { $_->office->id }
			       grep { $_->active }
			       @user_offices ];
    $form->default_values( \%values );
}

# Reconstruct the office labels and checkbox values from the submitted
# form data.
sub _fix_office_fields : Private {
    my $self = shift;
    my ( $c ) = @_;

    my $form = $c->stash->{form};
    if ( $form->param_value( 'office_counter' ) == 0 ) {
	# Repeatable ignores counter_name if the counter is 0, so we
	# have to call repeat manually.
	$form->get_field( 'office' )->repeat( 0 );
    }
    else {
	# The office names are Labels that are not submitted with the
	# form data, so we need to set their values to match the
	# submitted office ids.
	my $model = $c->model( 'TAPERDB::Office' );
	my @ids = $form->param_list( 'office_id' );
	my @names = map { $model->find( $_ )->name } @ids;
	$form->default_values( { office_name => \@names } );

	$c->forward( '_set_checkbox_values', \@ids );
    }
}

# Set the office_active checkbox values to the corresponding office_ids.
# (They start with value = 1 when loaded from the form config file.)
sub _set_checkbox_values : Private {
    my $self = shift;
    my ( $c, @ids ) = @_;

    my $form = $c->stash->{form};

    my $checkboxes = $form->get_fields( 'office_active' );
    my $ea = each_arrayref( $checkboxes, \@ids );
    while ( my ( $checkbox, $id ) = $ea->() ) {
	$checkbox->value( $id );
    }
}

# Add offices from the form to the user's set of offices.
sub _add_offices : Private {
    my $self = shift;
    my ( $c ) = @_;

    my $form = $c->stash->{form};
    my $user = $c->stash->{user};

    my $ids = Set::Scalar->new( $form->param_list( 'office_id' ) );
    my $active_ids = Set::Scalar->new( $form->param_list( 'office_active' ) );
    for my $id ( @$ids ) {
	my $active = $active_ids->has( $id ) ? 1 : 0;
	$user->add_to_user_offices( { office => $id, active => $active } );
    }
}


1;

=head1 NAME

TAPER::Controller::Dca::Users

=head1 DESCRIPTION

=head1 ACTIONS

=head2 Public Actions

The following documention describes, for each action, not just the
logic this module supplies, but a description of forms and other
information shown to the user via the associated TT templates and
FormFu forms.

=over

=item users

Path: dca/users/...

Chain root.

=item list

Path: dca/users/list

Displays a hyperlinked list of all the users known to TAPER.

=item add
=item add_FORM_NOT_SUBMITTED
=item add_FORM_NOT_VALID
=item add_FORM_VALID

Path: dca/users/add

Displays and handles a form that allows DCA staff to add a user.

=item user

Path: dca/users/user/$user_id/...

Chain part.  Puts the user with the given id into the stash.

=item edit
=item edit_FORM_NOT_SUBMITTED
=item edit_FORM_NOT_VALID
=item edit_FORM_VALID

Path: dca/users/user/$user_id/edit

Displays and handles a form that allows DCA staff to edit a user.

=back

=head2 Private Actions


These are private helper actions; you shouldn't need to use them directly.

=over

=item populate_office_menu
=item populate_user_form
=item fix_office_fields
=item set_checkbox_values
=item add_offices

=back

=head1 AUTHOR

Doug Orleans, Appleseed Software Consulting <dougo@appleseed-sc.com>

=head1 COPYRIGHT

Copyright (c) 2009-2010 by Tufts University.

=cut
