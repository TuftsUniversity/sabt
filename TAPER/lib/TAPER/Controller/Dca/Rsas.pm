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

package TAPER::Controller::Dca::Rsas;

use strict;
use warnings;
use parent 'Catalyst::Controller::HTML::FormFu';

use English;
use XML::LibXML;

__PACKAGE__->config->{namespace} = 'dca';

my $parser = XML::LibXML->new;

# rsas: A do-nothing chain root.
sub rsas : Chained('dca') CaptureArgs(0) {
}

# rsa: An arg-capturing pathpart that stuffs an RSA record into the stash.
#      Prelude to performing an edit, inventory, or a delete.
sub rsa : Chained('rsas') CaptureArgs(1) {
    my $self = shift;
    my ( $c, $rsa_id ) = @_;

    if ( $rsa_id ) {
        my $rsa = $c->model( 'RSA' )->find( $rsa_id );

        $c->stash->{rsa} = $rsa;
    }
    else {
        $c->res->redirect( $c->uri_for( '/dca' ) );
	$c->detach;
    }
}

sub edit : Chained('rsa') FormConfig('dca/rsa.yml') {
    my $self = shift;
    my ( $c ) = @_;

    my $rsa  = $c->stash->{rsa};

    $c->stash->{is_final} = $rsa->db_record->is_final;

    $c->stash->{template} = 'dca/rsa/edit.tt';
}

sub edit_FORM_SUBMITTED {
    my $self = shift;
    my ( $c ) = @_;

    $c->forward( '/validate_nonempty_repeatable',
		 [ qw( sipCreationAndTransfer formatType
                       copyright access ) ] );
    $c->forward( '/validate_extents' );
    $c->forward( '/validate_dateSpans' );
    $c->forward( '/validate_producers',
		 [ qw( recordsCreator recordsProducer ) ] );
}

sub edit_FORM_VALID {
    my $self = shift;
    my ( $c ) = @_;

    my $form = $c->stash->{form};
    my $rsa  = $c->stash->{rsa};

    # First, add an <edited> element to the RSA's audit trail.
    my $edit = TAPER::Logic::AuditStamp->new( {
	by => $c->taper_user->username,
	timestamp => DateTime->now,
    } );
    $rsa->add_edit( $edit );
    
    # Now have it update itself.
    $rsa->update_from_form( $form );

    $c->forward( '_populate_preservation_rules_menu' );
}

sub edit_FORM_NOT_SUBMITTED {
    my $self = shift;
    my ( $c ) = @_;

    my $form = $c->stash->{form};
    my $rsa  = $c->stash->{rsa};

    # Fill out the form with existing values.
    $rsa->populate_form( $form );
}

sub edit_FORM_RENDER {
    my $self = shift;
    my ( $c ) = @_;

    $c->forward( '_populate_preservation_rules_menu' );
}

sub _populate_preservation_rules_menu : Private {
    my $self = shift;
    my ( $c ) = @_;

    my $form = $c->stash->{form};
    my $fields = $form->get_fields( 'sipToAip' );
    my @rules = $c->model( 'TAPERDB::PreservationRule' )->search( undef, {
        order_by => 'number' } );
    for my $field ( @$fields ) {
        $field->options(
            [ [ '', '- Preservation Rule -' ],
              map {
                  [ $_->number, 'Rule ' . $_->number . ': ' . $_->description ]
              } @rules ] );
    }
}

sub inventory : Chained('rsa') {
    my $self = shift;
    my ( $c ) = @_;

    my $rsa = $c->stash->{rsa};
    $c->res->body( $rsa->inventory_zip );
    $c->res->content_type( 'application/zip' );
    $c->res->header( 'Content-Disposition' =>
                     'attachment; filename="inventory.zip"' );
}

sub delete_inventory : Chained('rsa') {
    my $self = shift;
    my ( $c ) = @_;

    my $rsa = $c->stash->{rsa};
    $c->flash->{deleted_inventory} = unlink( $rsa->inventory_documents );
    $c->flash->{deleted_inventory_rsa} = $rsa->id;
    $c->res->redirect( $c->uri_for( '/dca/rsas/archive' ) );
    $c->detach;
}

sub delete : Chained('rsa') {
    my $self = shift;
    my ( $c ) = @_;

    my $rsa = $c->stash->{rsa};
    my $action = $rsa->db_record->is_final ? 'archive' : 'drafts';
    $rsa->delete;
    $c->flash->{deleted_rsas} = 1;
    $c->res->redirect( $c->uri_for( "/dca/rsas/$action" ) );
    $c->detach;
}

sub drafts : Chained('rsas') {
    my $self = shift;
    my ( $c ) = @_;

    $c->forward( '_list' );
}

sub archive : Chained('rsas') {
    my $self = shift;
    my ( $c ) = @_;

    $c->stash->{archive} = 1;
    $c->forward( '_list' );
}

sub _list : Private {
    my $self = shift;
    my ( $c ) = @_;

    my $rsas = $c->req->params->{rsa};
    if ( defined $rsas ) {
	unless ( ref $rsas ) {
	    $rsas = [ $rsas ];
	}
	if ( $c->req->params->{delete} ) {
	    my $count = 0;
	    for my $id ( @$rsas ) {
		if ( my $rsa = $c->model( 'RSA' )->find( $id ) ) {
		    $rsa->delete;
		    $count++;
		}
	    }
	    $c->stash->{deleted_rsas} = $count;
	}
	else {
	    $c->res->body( $c->model( 'RSA' )->zip( @$rsas ) );
	    $c->res->content_type( 'application/x-zip-compressed' );
            $c->res->header( 'Content-Disposition' =>
                             'attachment; filename="agreements.zip"' );
	    $c->detach;
	}
    }

    $c->stash->{template} = 'dca/rsa/list.tt';
    if ( $c->stash->{archive} ) {
	$c->stash->{rsas} = [ $c->model( 'RSA' )->archive ];
    }
    else {
	$c->stash->{rsas} = [ $c->model( 'RSA' )->drafts ];
    }
}

1;

=head1 NAME

TAPER::Controller::Dca::Rsas

=head1 DESCRIPTION

Catalyst controller for giving DCA staff CRUD control over RSAs.

=head1 ACTIONS

=head2 Public Actions

The following documention describes, for each action, not just the
logic this module supplies, but a description of forms and other
information shown to the user via the associated TT templates and
FormFu forms.

=over

=item rsas

Path: dca/rsas/...

Chain root. No logic applied here.

=item rsa

Path: dca/rsas/rsa/$rsa_id/...

Chain part. Captures an RSA id, fetches the corresponding RSA object,
and stores it in the stash before passing control along.

If the supplied RSA ID isn't valid, redirects the user to /dca.

=item edit
=item edit_FORM_SUBMITTED
=item edit_FORM_VALID
=item edit_FORM_NOT_SUBMITTED
=item edit_FORM_RENDER

Path: dca/rsas/rsa/$rsa_id/edit

Displays and handles a form that allows DCA staff to edit an RSA.

=item inventory

Path: dca/rsas/rsa/$rsa_id/inventory

Produces a zip file containing all the inventory documents of the RSA.

=item delete_inventory

Path: dca/rsas/rsa/$rsa_id/delete_inventory

Deletes all the inventory documents of the RSA.

=item delete

Path: dca/rsas/rsa/$rsa_id/delete

Deletes the RSA entirely.

=item drafts

Path: dca/rsas/drafts

Displays a hyperlinked list of RSAs that have been submitted by users
for DCA staff approval, but which have not yet been completed.  If the
form has been submitted via the "delete" button, deletes the selected
RSAs.

=item archive

Path: dca/rsas/archive

Displays a hyperlinked list of RSAs that have been completed.  If the
form has been submitted via the "download" button, produces a zip file
of the selected RSAs as XML; if the form has been submitted via the
"delete" button, deletes the selected RSAs.

=back

=head1 AUTHOR

Jason McIntosh, Appleseed Software Consulting <jmac@appleseed-sc.com>
Doug Orleans, Appleseed Software Consulting <dougo@appleseed-sc.com>

=head1 COPYRIGHT

Copyright (c) 2009-2010 by Tufts University.


