package TAPER::Controller::CreateRsa;

use strict;
use warnings;
use parent 'Catalyst::Controller::HTML::FormFu';

use English;
use DateTime;

use XML::LibXML;

use Readonly;
Readonly my $XMLS_NS =>'http://www.w3.org/2001/XMLSchema-instance';

__PACKAGE__->config->{namespace} = 'create_rsa';

sub create_rsa : PathPart('create_rsa') Chained('/') CaptureArgs(0) {
    my $self = shift;
    my ( $c ) = @_;

    unless ( defined $c->taper_user ) {
	$c->res->redirect( $c->uri_for( '/auth/login',
                                        { page => '/create_rsa' } ) );
	$c->detach;
    }
}

sub ssa : PathPart('') Chained('create_rsa') Args(0) {
    my $self = shift;
    my ( $c ) = @_;

    # See if the form's been submitted.
    if ( my $ssa_id = $c->req->params->{ssa_id} ) {
        # Why yes. Redirect to the RSA creation form, given this SSA ID.
        $c->res->redirect(
            $c->uri_for( "/create_rsa/rsa/$ssa_id" )
        );
    }
}

sub rsa : Chained('create_rsa') FormConfig {
    my $self = shift;
    my ( $c, $ssa_id ) = @_;

    unless ( $ssa_id ) {
        # User has no business being here without an SSA ID.
        $c->res->redirect(
            $c->uri_for( '/create_rsa/' )
        );
	return;
    }

    # Try to load the referred SSA document from the DB.
    my ( $ssa ) = $c->model( 'SSA' )->find( $ssa_id );
    unless ( $ssa ) {
        # No SSA with that ID? Display an error message.
        $c->flash->{ssa_not_found} = 1;
        $c->flash->{ssa_id} = $ssa_id;
        $c->res->redirect(
            $c->uri_for( '/create_rsa/' )
        );
	return;
    }

    $c->stash->{ssa} = $ssa;
    $c->stash->{producer} = TAPER::Logic::Producer->new_from_user( $c->user );

    my $form = $c->stash->{form};

    # Populate the form with default values even if it's already been
    # submitted, because this might add selection options.  Submitted
    # values will override default values.
    $ssa->populate_form( $form );
}

sub rsa_FORM_SUBMITTED {
    my $self = shift;
    my ( $c ) = @_;

    $c->forward( '/validate_extents' );
    $c->forward( '/validate_dateSpans' );
}

sub rsa_FORM_VALID {
    my $self = shift;
    my ( $c ) = @_;

    # Looks like a good RSA form. All right... let's create
    # a new RSA document, and get the submission process started.

    my $form = $c->stash->{form};
    my $ssa = $c->stash->{ssa};

    my $rsa = $c->model( 'RSA' )->create_from_form( $form, $ssa );

    # Bring the user to the attachment screen.
    $c->res->redirect(
	$c->uri_for(
	    '/create_rsa/inventory/'
	    . $rsa->id
	    . '/upload'
	)
    );
}

sub inventory : Chained('create_rsa') CaptureArgs(1) {
    my $self = shift;
    my ( $c, $rsa_id ) = @_;

    my $rsa = $c->model( 'RSA' )->find( $rsa_id );
    $c->stash->{rsa} = $rsa;
}

sub inventory_text :Chained('inventory') PathPart('text') FormConfig {
}

sub inventory_text_FORM_VALID {
    my $self = shift;
    my ( $c ) = @_;

    my $form = $c->stash->{form};
    my $rsa = $c->stash->{rsa};
    
    my $inventory_path = File::Spec->catdir(
	$c->config->{rsa_staging_directory},
	$rsa->id,
	'inventory',
    );

    my $file_path = File::Spec->catfile(
	$inventory_path,
	'inventory.txt',
    );
    
    open my $inventory_handle, '>', $file_path
	or die "Can't write to $file_path: $OS_ERROR";
    print $inventory_handle $form->param_value( 'inventory' );
    close $inventory_handle;

    $c->forward( 'complete_submission' );
}

sub inventory_upload :Chained('inventory') PathPart('upload') FormConfig {
}

sub inventory_upload_FORM_VALID {
    my $self = shift;
    my ( $c ) = @_;

    my $rsa = $c->stash->{rsa};

    my $inventory_path = File::Spec->catdir(
	$c->config->{rsa_staging_directory},
	$rsa->id,
	'inventory',
    );

    # Now just write out each file.

    my $files = $c->req->uploads->{file};
    unless ( ref $files && ref $files eq 'ARRAY' ) {
	$files = [ $files ];
    }

    for my $upload ( @$files ) {
	my $filename = $upload->filename;
	my $target   = File::Spec->catfile( $inventory_path, $filename );

	unless ( $upload->link_to( $target)
		 || $upload->copy_to( $target ) ) {
	    die "Can't write $filename to $target: $OS_ERROR";
	}
    }

    $c->forward( 'complete_submission' );
}

sub complete_submission :Private {
    my $self = shift;
    my ( $c ) = @_;

    # Mail DCA staff about the new RSA.
    $c->email(
        header =>
            [ To      => $c->config->{dca_staff_email},
              From    => $c->config->{from_name} 
	                 . ' <'
	                 . $c->config->{from_address}
	                 . '>',
              Subject => $c->view('NoWrapperTT')
                  ->render($c,'new_rsa_notification/subject.tt2')
              ],
        body   => $c->view('NoWrapperTT')->render($c,'new_rsa_notification/body.tt2'),
    );
        
    # Kick the user back to the RSA-creation front page.
    $c->flash->{rsa_complete} = 1;
    $c->flash->{rsa} = $c->stash->{rsa};
    $c->res->redirect( $c->uri_for( '/create_rsa' ) );
}

1;

=head1 NAME

TAPER::Controller::CreateRsa

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

=item create_rsa

Path: create_rsa

Chain root. It just checks that the user is logged in, and redirects
them to the login page if not.

=item ssa

Path: create_rsa/ssa

Displays and handles the choose-an-SSA form that users see before they
can start filling out the RSA form.

=item rsa
=item rsa_FORM_SUBMITTED
=item rsa_FORM_VALID

Path: create_rsa/rsa

Displays and handles the RSA creation form. This is the center of
activity for this controller.

=item inventory

Path: create_rsa/inventory/*/...

Chained midsection that captures one argument.

After users fill in the RSA form, they must attach some inventory
information. The actions that chain off this one (see below) display
and handle the different ways that users can provide this information.

=item inventory_text
=item inventory_text_FORM_VALID

Path: create_rsa/inventory/*/text

Displays and handles the form that lets users compose a plain-text
inventory file on the spot.

=item inventory_upload
=item inventory_upload_FORM_VALID

Path: create_rsa/inventory/*/inventory_upload

Displays and handles the form that lets users upload inventory files
from their own machines.

=back

=head2 Private Actions

=over

=item complete_submission

Called when the user's done making an RSA draft and has attached all
the inventory documents. Sends email to the DCA staff, and then kicks
the user back to the create_rsa action, with a message saying that DCA
has been notified.  Also, if the RSA had a drop box URL (inherited
from its SSA), a hyperlink to it is displayed, leaving it to the user
to take care of business from there if needed (since the link leads
outside of the control of this application).


=back

=head1 AUTHOR

Jason McIntosh, Appleseed Software Consulting <jmac@appleseed-sc.com>
Doug Orleans, Appleseed Software Consulting <dougo@appleseed-sc.com>

=head1 COPYRIGHT

Copyright (c) 2009-2010 by Tufts University.
