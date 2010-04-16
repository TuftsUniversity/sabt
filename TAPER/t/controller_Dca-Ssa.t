#!/usr/bin/perl

# Test the DCA SSA controller.

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

my $mech = TAPERTest->login( 'alice' );

$mech->get_ok('/dca/ssas/create', 'Create a new SSA');

$mech->submit_form_ok(
    {
	with_fields => {
	    recordsCreator_id => '123',
	    recordsCreator_name => 'creator',
	    recordsProducer_id => '456',
	    recordsProducer_name => 'producer',
	    office_id => 1,
	    archiveEndorsement_day => 10,
	    archiveEndorsement_month => 10,
	    archiveEndorsement_year => 2009,
	    recordType => 'Test SSA 1',
	    copyright => '(C) Alice 2009',
	    access => 'Category 42',
	    dropboxUrl => 'http://example.com/dropbox',
	    generalRecordsDescription => 'This is the test SSA number 1.',
	    warrantToCollect => 'University Records Policy',
	    respectDeFonds => 'Ayyyy.',
	},
    },
    'Submitted SSA creation form.' );

$mech->get_ok('/dca/ssas/list', 'List the SSAs');

$mech->follow_link_ok( { text => 'Test SSA 1' }, 'Edit SSA 1' );

$mech->content_like( qr/access.*Category 42/,
		     'Checked access.' );
$mech->content_like( qr/generalRecordsDescription.*This is the test SSA/,
		     'Checked generalRecordsDescription.' );
$mech->content_like( qr/warrantToCollect.*University Records Policy/,
		     'Checked warrantToCollect.');

$mech->submit_form_ok(
    {
	with_fields => {
	    access => 'Front 242',
	    generalRecordsDescription => 'This is the edited desc.',
	    warrantToCollect => 'dead or alive',
	},
    },
    'Submitted SSA edit form.' );

$mech->content_like( qr/SSA successfully updated./, 'Successfully edited.' );

$mech->follow_link_ok( { text => 'Return to SSA list' }, 'List the SSAs' );

$mech->follow_link_ok( { text => 'Test SSA 1' }, 'Edit SSA 1' );

$mech->content_like( qr/access.*Front 242/,
		     'Checked access.' );
$mech->content_like( qr/generalRecordsDescription.*This is the edited desc/,
		     'Checked generalRecordsDescription.' );
$mech->content_like( qr/warrantToCollect.*dead or alive/,
		     'Checked warrantToCollect.');
