package TAPER::Controller::Dca;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use English;

sub dca : Chained('/') CaptureArgs(0) {
    my $self = shift;
    my ( $c ) = @_;

    if ( defined $c->taper_user ) {

	# Make sure that the current user is DCA staff.
	# Unfortunately, we can't use $c->assert_user_roles here, because
	# it expects us to be using LDAP roles, and Tufts' LDAP just isn't
	# set up to do that. So we've got to roll our own solution.
	unless ( $c->taper_user->is_dca ) {
	    $c->log->warn( 'Attempt by unauthorized user '
			   . $c->taper_user->username
			   . ' to access DCA area.' );
	    $c->res->redirect( $c->uri_for ( '/' ) );
	    $c->detach;
	}

    } else {
	$c->res->redirect( $c->uri_for ( '/auth/login', { page => '/dca' } ) );
	$c->detach;
    }

}

sub index : Chained('dca') PathPart('') Args(0) ActionClass('RenderView') {}

1;

=head1 NAME

TAPER::Controller::Dca

=head1 DESCRIPTION

Catalyst controller for actions restricted to use by DCA staff.

All it really provides is a single chianed-root action, which other
controllers are free to extend in order to place themselves under this
restriction.

=head1 ACTIONS

=head2 Public Actions

The following documention describes, for each action, not just the
logic this module supplies, but a description of forms and other
information shown to the user via the associated TT templates and
FormFu forms.

=over

=item dca

Path: dca/...

Chain root. Before passing along control to the next part of the
chain, it makes sure that the current web user has DCA staff
permissions, according to our database.

If not, it logs a warning and kicks the user over the application
root. (Or to the application's login page, if the web user doesn't
seem to have been authenticated at all.)

=item index

Path: dca/

Displays the main page of links to DCA staff-only TAPER activities.

Otherwise performs no logic.

=back

=head1 AUTHOR

Jason McIntosh, Appleseed Software Consulting <jmac@appleseed-sc.com>

=head1 COPYRIGHT

Copyright (c) 2009 by Tufts University.


