package TAPER;

use strict;
use warnings;

use Catalyst::Runtime '5.70';

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root 
#                 directory

use parent qw/Catalyst/;
use Catalyst qw/
                Session
                Session::State::Cookie
                Session::Store::File
                ConfigLoader
                Static::Simple
                Authentication
                Authorization::Roles
                Cache
                Cache::Store::Memory
                Email
                DateTime
               /;
our $VERSION = '0.01';

# All config's in taper.conf.
# Here are some defaults...

# Turn on Session's flash-to-stash feature.
__PACKAGE__->config( session => { flash_to_stash => 1 } );

# Provide an empty config for the Cache plugin, because otherwise it complains.
__PACKAGE__->config( 'Plugin::Cache' => { } );

# Check for an env var pointing to a different site-config file.
if ( defined $ENV{TAPER_SITE_CONFIG} ) {
    __PACKAGE__->config( 'Plugin::ConfigLoader' => {
	file => $ENV{TAPER_SITE_CONFIG},
    } );
}

#######################
# View configuration
#######################
# Here's the HTML view, which is the default.
__PACKAGE__->config->{'View::TT'} =
    {
        INCLUDE_PATH => [
            __PACKAGE__->path_to( qw ( root mail ) ),
            __PACKAGE__->path_to( qw ( root src ) ),
            __PACKAGE__->path_to( qw ( root lib ) ),
        ],
        CATALYST_VAR => 'Catalyst',
        WRAPPER => 'wrapper',
    };
__PACKAGE__->config->{default_view} = 'TT';

# Here's the plain-text view, whch is just like the HTML view except that
# it doesn't apply the wrapper template to it. Good for emails and stuff.
__PACKAGE__->config->{'View::NoWrapperTT'} =
    {
        INCLUDE_PATH => [
            __PACKAGE__->path_to( qw ( root mail ) ),
            __PACKAGE__->path_to( qw ( root src ) ),
            __PACKAGE__->path_to( qw ( root lib ) ),
        ],
        CATALYST_VAR => 'Catalyst',
    };

# Have the Static::Simple plugin handle everything _except_ TT files.                       
__PACKAGE__->config->{'Plugin::Static::Simple'}->{ignore_extensions} = [ qw/ tt tt2 / ];

# Set up role-based authorization.
__PACKAGE__->config->{authorization}{dbic} = {
    role_class           => 'TAPERDB::Role',
    role_field           => 'name',
    user_role_user_field => 'user',
    role_rel             => 'user_role',
};

# Start the application
__PACKAGE__->setup();

# Other accessors n stuff.
sub taper_user {
    my $c = shift;

    unless ( $c->stash->{taper_user} ) {
        if ( $c->user ) {
            my ( $taper_user ) = $c->model( 'TAPERDB::User' )
		->search( { username => $c->user->id } );
            $c->stash->{taper_user} = $taper_user;
        }
    }

    return $c->stash->{taper_user};
}

=head1 NAME

TAPER - Catalyst-based TAPER support application

=head1 SYNOPSIS

    script/taper_server.pl

=head1 NAME

TAPER - Catalyst based application

=head1 SYNOPSIS

    script/taper_server.pl

=head1 DESCRIPTION

This is the main module for the TAPER web application. As with most Catalyst-based applications, most of the program logic is found in the various Controller, Schema and Logic modules. See L<"SEE ALSO"> for a complete list.

For more information about turning all this code into a working web application, see L<Catalyst>.

=head1 METHODS

This application class supports all the usual Catalyst methods, plus this custom one:

=over

=item taper_user

If the current session has a user signed in, then this method returns
that user's corresponding database record, of class
TAPER::Model::TAPERDB::User.

This is separate from the user() method, which returns their LDAP user
info... which, due to the fact that Tufts LDAP isn't good for much
else beyond authentication, isn't very interesting.

If there is no user signed in, then this returns undef.

=back

=head1 SEE ALSO

=head2 Controllers

=over

=item TAPER::Controller::Root

The root controller.

=item TAPER::Controller::CreateRsa

The controller for the handholding, community-friendly submission agreement builder tool.

=item TAPER::Controller::Dca

The root controller for the access-controlled, DCA-staff-only sections of the TAPER web application.

=item TAPER::Controller::Dca::Rsas

Controller for DCA-level CRUD manipulation of Regular Submission Agreements.

=item TAPER::Controller::Dca::Ssa

Controller for DCA-level CRUD manipulation of Regular Submission Agreements.

=item TAPER::Controller::Dca::Offices

Controller for DCA-level CRUD manipulation of offices.

=item TAPER::Controller::Dca::Users

Controller for DCA-level CRUD manipulation of users.

=item TAPER::Controller::Auth

Controller for managing logins and logouts, primarily through LDAP.

=back

=head2 Models

=over

=item TAPER::Model::TAPERDB

The interface to the TAPER database.

=item TAPER::Model::RSA

An interface to Regular Submission Agreement XML documents and related metdata.

=item TAPER::Model::SSA

An interface to Standard Submission Agreement XML documents and related metdata.

=back

=head1 AUTHOR

Jason McIntosh, Appleseed Software Consulting <jmac@appleseed-sc.com>
Doug Orleans, Appleseed Software Consulting <dougo@appleseed-sc.com>

=head1 COPYRIGHT

Copyright (c) 2009-2010 Tufts University.

=cut

1;
