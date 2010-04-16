#!/usr/bin/perl

# Test the CreateRsa controller.

use warnings;
use strict;

use FindBin;
use lib (
    "$FindBin::Bin/../lib",
    "$FindBin::Bin/lib",
);

use TAPERTest;
my $schema = TAPERTest->init_schema;

use Test::More tests => 19;
use Test::WWW::Mechanize::Catalyst 'TAPER';

my $mech = TAPERTest->login( 'bob' );

use Email::Send::Test;

# Clear the email test array.
Email::Send::Test->clear;

# Set up some useful constants
use Readonly;
Readonly my $STAGING_DIR => TAPER->config->{rsa_staging_directory};

# Visit the RSA submission form.
$mech->get_ok('/create_rsa/', 'Hit the Submission Agreement builder');

# Submit a form to choose an SSA.
$mech->submit_form_ok(
    {
	with_fields => {
	    ssa_id  => 1,
	}
    },
    'Submitted SSA form',
);

# Submit a form to make an RSA.

# In order to give the RSA multiple values for repeatable fields, we
# have to make several calls to set_fields explicitly, because the
# submit_form method doesn't handle duplicate fields.

$mech->form_with_fields( 'sipCreationAndTransfer' );
$mech->set_fields(
    sipCreationAndTransfer      => 'label_box',
    generalRecordsDescription   => 'Spinal Tap drummers',
    extent_value                => 100,
    extent_units                => 'file',
    formatType                  => 'photographic_prints',
    dateSpan_start              => 2000,
    dateSpan_end                => 2525,
    arrangementAndNamingScheme  => 'chronological',
    recordKeepingSystem         => 'not_applicable',
);

# To set a field other than the first occurrence of its name, use an
# array whose second element is the field number (starting at 1).

$mech->set_fields(
    sipCreationAndTransfer      => ['create_inventory', 2],
    formatType                  => ['digital_media', 2],
);

# Submit the currently-selected form.
$mech->submit_form_ok( { fields => { } }, 'Submitted RSA form' );

# Submit a plain-text inventory description.
$mech->follow_link_ok( { text_regex => qr/plain-text/ },
		       'Plain-text inventory description page' );
$mech->submit_form_ok(
    { 
        with_fields => {
            inventory => 'Blah blah, some inventory.'
        },
    },
    'Added plain-text inventory description'
);

$mech->content_contains( 'Meeting Minutes and Agenda', 'Saw SSA recordType' );

$mech->content_contains( 'href="http://example.com/dropbox" target="_blank"',
			 'Saw dropbox URL' );

# Wait a second as things digest.
sleep 1;

# Check that the right stuff has appeared in the staging area.
ok (-e "$STAGING_DIR/2", 'Staging dir has a directory in it');
ok (-e "$STAGING_DIR/2/2.xml", 'RSA file appears to be present');
ok (-e "$STAGING_DIR/2/inventory", "Inventory directory is present");
ok (-e "$STAGING_DIR/2/inventory/inventory.txt",
    'Inventory file appears to be present');

# Check that the multiple field values show up in the XML file.

my $xmlfile = "$STAGING_DIR/2/2.xml";

use File::Grep qw( fgrep );
ok( ( fgrep { /label_box/ } $xmlfile ),
    'Found label_box.' );
ok( ( fgrep { /create_inventory/ } $xmlfile ),
    'Found create_inventory.' );
ok( ( fgrep { /photographic_prints/ } $xmlfile ),
    'Found photographic_prints.' );
ok( ( fgrep { /digital_media/ } $xmlfile ),
    'Found digital_media.' );

# Make sure that everyone got notified properly.
my @emails = Email::Send::Test->emails;
is (@emails, 1, 'Got the right number of emails.');

is ($emails[0]->header('To'), 'dca@example.com',
    'The (fake) DCA staff received an email.'
);

like ( $emails[0]->header('Subject'), qr/New RSA submission/,
       'Email subject line looks OK.'
);

like ( $emails[0]->body, qr/The user bob has just submitted/,
       'Email body looks OK.'
);
