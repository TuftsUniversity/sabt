#!/usr/bin/perl

# Test the TAPER authentication system.

use warnings;
use strict;

use FindBin;
use lib (
    "$FindBin::Bin/../lib",
    "$FindBin::Bin/lib",
);

use TAPERTest;
my $schema = TAPERTest->init_schema;

use Test::More qw( no_plan );
use Test::WWW::Mechanize::Catalyst 'TAPER';

my $mech = Test::WWW::Mechanize::Catalyst->new;

# Have 'alice' log in to the site.
$mech->get_ok('/auth/login', 'Hit the login page');
$mech->content_like(qr/log in/, 'Login page looks good');

# It doesn't matter what we pass in here, since the test site is configured to accept
# any input as a valid LDAP user. The controller will still check that the user
# exists in the local database, though.
$mech->submit_form_ok(
    {
        with_fields => {
            username => 'alice',
            password => 'alicepassword',
            login_form_submit => 'Log in',
        }
    },
    'Submitted login form',
);

# It should redirect to the root page.
is( $mech->uri->path, "/", 'Login seems to have worked');

# Now test logging in as an unknown user.
$mech->get_ok('/auth/login', 'Hit the login page');
$mech->submit_form_ok(
    {
        with_fields => {
            username => 'baduser',
            password => 'baduserpass',
            login_form_submit => 'Log in',
        }
    },
    'Submitted login form',
);
$mech->content_like(qr/Unregistered/, 'Unregistered login seems to have worked');
