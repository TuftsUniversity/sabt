#!/usr/bin/perl

# Test the DCA offices controller.

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

$mech->follow_link_ok( { text => 'Manage Offices and Units' },
		       'Visit office list page' );
$mech->follow_link_ok( { text => 'Dept of Widget Studies' },
		       'Edit the office' );
$mech->submit_form_ok( { with_fields => { name => 'Dept of Redundancy Dept' } },
		       'Change the office name' );
$mech->follow_link_ok( { text => 'Return to office list' },
		       'Return to office list' );
$mech->has_tag( 'a', 'Dept of Redundancy Dept',
		'Name was changed' );
$mech->submit_form_ok( { with_fields => { name => 'Office of the Ombudsman' } },
		       'Add a new office' );
$mech->has_tag( 'a', 'Office of the Ombudsman',
		'Office was added' );

$mech->follow_link_ok( { text => 'Office of the Ombudsman' },
                       'Edit the office' );
$mech->form_id( 'deleteForm' );
$mech->click_ok( 'delete',
                 'Delete the office' );
$mech->reload;
$mech->content_lacks( 'Ombudsman',
                      'Office was deleted' );
