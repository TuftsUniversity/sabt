#!/usr/bin/perl

# Test the DCA RSAs controller.

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

# Look for the test RSA on the drafts page.
$mech->get_ok( '/dca/rsas/drafts', 'Visited drafts page.' );
$mech->content_like( qr/Meeting Minutes/, 'Record type is on drafts page.' );

$mech->follow_link_ok( { text => 'Edit' }, 'Followed draft edit link.' );

$mech->content_like( qr/sipCreationAndTransfer.*label_box/,
		     'Checked sipCreationAndTransfer 1.' );
$mech->content_like( qr/sipCreationAndTransfer.*create_inventory/,
		     'Checked sipCreationAndTransfer 2.' );
$mech->content_like( qr/generalRecordsDescription.*Paragraph goes here/,
		     'Checked generalRecordsDescription.' );
$mech->content_like( qr/formatType.*photographic_prints/,
		     'Checked formatType 1.' );
$mech->content_like( qr/formatType.*digital_media/,
		     'Checked formatType 2.' );
$mech->content_like( qr/arrangementAndNamingScheme.*chronological/,
		     'Checked arrangementAndNamingScheme.' );

# Check an inherited SSA field.
$mech->content_like( qr/Copyright.*Allen Anderson/,
		     'Checked inherited Copyright.' );

# Edit some fields and set it to final.
$mech->submit_form_ok(
    {
	with_fields => {
	    generalRecordsDescription => 'Photos of Spinal Tap drummers.',
	    activityLogNumber => '69,105',
	    transferDate_day => '10',
	    transferDate_month => '11',
	    transferDate_year => '2009',
	    is_final => 1,
	},
    },
    'Submitted edit form.');

# Make sure it moved from the drafts page to the archive page.
$mech->get( '/dca/rsas/drafts' );
$mech->content_lacks( 'Meeting Minutes', 'No longer on the drafts page.' );

$mech->get_ok( '/dca/rsas/archive', 'Visited archive page.' );
$mech->follow_link_ok( { text => 'Edit' }, 'Followed archive edit link.' );

$mech->content_like( qr/sipCreationAndTransfer.*label_box/,
		     'Checked sipCreationAndTransfer 1.' );
$mech->content_like( qr/sipCreationAndTransfer.*create_inventory/,
		     'Checked sipCreationAndTransfer 2.' );
$mech->content_like( qr/generalRecordsDescription.*Photos of Spinal Tap/,
		     'Checked generalRecordsDescription.' );
$mech->content_like( qr/formatType.*photographic_prints/,
		     'Checked formatType 1.' );
$mech->content_like( qr/formatType.*digital_media/,
		     'Checked formatType 2.' );
$mech->content_like( qr/activityLogNumber.*69,105/,
		     'Checked activityLogNumber.' );

$mech->back;
$mech->submit_form_ok( { with_fields => { rsa => 1 }, button => 'delete', },
                       'Submitted delete form.' );
$mech->base_like( qr{/dca/rsas/archive}, 'Ended up back on archive page.' );
$mech->content_like( qr/eleted/, 'Saw deleted message.' );
$mech->content_lacks( 'Meeting Minutes', 'No longer on archive page.' );
