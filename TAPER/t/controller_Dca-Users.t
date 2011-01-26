#!/usr/bin/perl

# Test the DCA users controller.

use strict;
use warnings;

use FindBin;
use lib (
    "$FindBin::Bin/../lib",
    "$FindBin::Bin/lib",
);

use TAPERTest;
my $schema = TAPERTest->init_schema;

use Test::More qw( no_plan );
use Test::WWW::Mechanize::Catalyst 'TAPER';

my $mech = TAPERTest->login( 'alice' );

$mech->get( '/dca' );

$mech->follow_link_ok( { text => 'Manage Users' },
		       'Visit user list page' );
$mech->content_like( qr/Dobbs.*Liddell/s,
		     'User names are alphabetized' );
$mech->follow_link_ok( { text_regex => qr/new user/ },
		       'Add a new user' );

$mech->submit_form_ok(
    { with_fields => {
	username => 'carol',
	first_name => 'Carol',
	last_name => 'von Bells',
	is_dca => 1,
      } },
    'Submit new user carol' );

$mech->follow_link_ok( { url_regex => qr(3/edit) },
		       'Edit carol' );

ok( $mech->form_with_fields( 'username', 'is_dca', ),
    'Find the edit form' );
is( $mech->current_form->value( 'last_name' ), 'von Bells',
    'Check last name' );
ok( $mech->current_form->value( 'is_dca' ),
    'Check is_dca' );


$mech->back;
$mech->follow_link_ok( { url_regex => qr(2/edit) },
		       'Edit bob' );

ok( $mech->form_with_fields( 'office_id', 'office_active' ),
    'Find the edit form' );
cmp_ok( [ $mech->current_form->param( 'office_id' ) ], '~~', [ 2, 1, 6 ],
	'Check offices' );
is( $mech->current_form->param( 'office_active' ), 1,
	'Check office 1 is active' );

$mech->set_fields( last_name => 'Robertson', is_dca => 0 );
$mech->field( office_active => 2, 1 );
$mech->submit_form_ok( {},
		       'Submit edited bob' );

$mech->form_with_fields( 'username', 'is_dca', 'office_id' );

is( $mech->current_form->value( 'last_name' ), 'Robertson',
    'Check edited last name' );
ok( !$mech->current_form->value( 'is_dca' ),
    'Check edited is_dca' );
cmp_ok( [ $mech->current_form->param( 'office_active' ) ], '~~', [ 2, 1 ],
    'Check office 1 is active, 6 still inactive' );

$mech->form_id( 'deleteForm' );
$mech->click_ok( 'delete', 'Hit delete button' );
$mech->content_lacks( 'Robertson', 'User deleted' );
