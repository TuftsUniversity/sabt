#
# COPYRIGHT:
#
# Copyright 2010, 2011 Tufts University.
#
#
# FUNDING:
#
# The development of the TAPER software suite was funded by the
# National Historic Publications and Records Commission (NHPRC).
# Grant number RE10005-08.
#
#
# LICENSE:
#
# This file is part of the TAPER software suite.
#
# The TAPER software suite is free software: you can redistribute
# it and/or modify it under the terms of the GNU Affero General
# Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later
# version.
#
# The TAPER software suite is distributed in the hope that it will
# be useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public
# License along with the TAPER software suite.  If not, see
# <http://www.gnu.org/licenses/>.
#

package TAPER::Controller::Auth;

use strict;
use warnings;
use parent 'Catalyst::Controller::HTML::FormFu';

sub login : Local FormConfig {
}

sub login_FORM_SUBMITTED {
    my $self = shift;
    my ( $c ) = @_;

    my $form = $c->stash->{form};

    my $username = $form->param_value( 'username' );
    my $password = $form->param_value( 'password' );

    my $auth_params = {
	id       => $username,
	password => $password,
    };
    
    if ( $c->authenticate( $auth_params ) ) {

	# They passed LDAP authentication. Now check to see if this user's
	# in the TAPER-user DB.
	my ( $taper_user ) = $c->model( 'TAPERDB::User' )
	    ->search( { username => $username } );
	if ( $taper_user ) {
	    # Yep, they're good to go.
	    # Now kick the user to the front page.
	    $c->res->redirect($c->uri_for( $c->req->params->{page} || '/' ));
	}
	else {
	    # This user is Tufts-valid, but unknown to this application.
	    # Zap their authentication, and display an explanation.
	    $c->logout;
	    $c->res->redirect( $c->uri_for( '/auth/unregistered' ) );
	}
    }
    else {
	# User failed LDAP authentication.
	# Display an error and let them try again.
	$form->force_error_message(1);
	$form->form_error_message($form->stash->{bad_auth_message});
    }
}

sub unregistered :Local {
}

sub logout : Local {
    my $self = shift;
    my ($c) = @_;

    if ($c->user) {
        $c->logout;
    }

    $c->res->redirect($c->uri_for('/auth/login'));
}

1;

=head1 NAME

TAPER::Controller::Auth

=head1 DESCRIPTION

Catalyst controller for handling user authentication in the TAPER app.

=head1 ACTIONS

=head2 Public Actions

The following documention describes, for each action, not just the
logic this module supplies, but a description of forms and other
information shown to the user via the associated TT templates and
FormFu forms.

=over

=item login
=item login_FORM_SUBMITTED

Path: auth/login

Displays and handles the login form.

If username and password are both supplied, then it tries to
authenticate the user against Tufts LDAP. On success, it then checks
TAPER's own DB to make sure that the user's present there, as well. If
I<that> works, the user is forwarded the application root. Otherwise,
they're sent to the 'unregistered' action (see below).

=item unregistered

Path: auth/unregistered

Displays a page explaining that the user seems to be present in Tufts
LDAP, but is not a registered TAPER user, and suggests some paths they
can take to rectify this.

Doesn't do any logic, otherwise.

=item logout

Path: auth/logout

Logs out the user, and returns them to the root path.

=back

=head1 AUTHOR

Jason McIntosh, Appleseed Software Consulting <jmac@appleseed-sc.com>

=head1 COPYRIGHT

Copyright (c) 2009 by Tufts University.


