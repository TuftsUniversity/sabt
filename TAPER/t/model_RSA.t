#!/usr/bin/perl

use strict;
use warnings;
use Test::More qw( no_plan );
use List::MoreUtils qw( any );

use FindBin;
use lib (
    "$FindBin::Bin/../lib",
    "$FindBin::Bin/lib",
);

use TAPERTest;
TAPERTest->init_schema;

use TAPER;
my $c = TAPER->new;
$c->authenticate( { id => 'alice', password => 'password' } );

# In order to create an RSA, we need an HTML form.

my $form = HTML::FormFu->new;
$form->load_config_file( "$FindBin::Bin/../root/forms/create_rsa/rsa.yml" );
$form->process( {
    sipCreationAndTransfer      => [ 'label_box', 'create_inventory' ],
    generalRecordsDescription   => 'Spinal Tap drummers',
    extent_value                => 100,
    extent_units                => 'file',
    formatType                  => [ 'photographic_prints', 'digital_media' ],
    dateSpan_start              => 2000,
    dateSpan_end                => 2525,
    arrangementAndNamingScheme  => 'chronological',
    recordKeepingSystem         => 'not_applicable',
} );

my $ssa = $c->model( 'SSA' )->find( 1 );

# Create the RSA.
ok( my $rsa = $c->model( 'RSA' )->create_from_form( $form, $ssa ),
    'Created RSA.' );

# Check some fields, including one inherited from the SSA.
is_deeply( $rsa->sipCreationAndTransfer, [ 'label_box', 'create_inventory' ],
    'Checked sipCreationAndTransfer.' );
is( $rsa->generalRecordsDescription, 'Spinal Tap drummers',
    'Checked generalRecordsDescription.' );
is_deeply( $rsa->formatType, [ 'photographic_prints', 'digital_media' ],
    'Checked formatType.' );
is_deeply( $rsa->arrangementAndNamingScheme, [ 'chronological' ],
    'Checked arrangementAndNamingScheme.' );
like( $rsa->copyright->[0], qr/Allen Anderson/,
    'Checked copyright.' );

# Lookup the RSA by its id.
ok( $rsa = $c->model( 'RSA' )->find( $rsa->id ), 'Found RSA.' );

# Check the fields again.
is_deeply( $rsa->sipCreationAndTransfer, [ 'label_box', 'create_inventory' ],
    'Checked sipCreationAndTransfer.' );
is( $rsa->generalRecordsDescription, 'Spinal Tap drummers',
    'Checked generalRecordsDescription.' );
is_deeply( $rsa->formatType, [ 'photographic_prints', 'digital_media' ],
    'Checked formatType.' );
is_deeply( $rsa->arrangementAndNamingScheme, [ 'chronological' ],
    'Checked arrangementAndNamingScheme.' );
like( $rsa->copyright->[0], qr/Allen Anderson/,
    'Checked copyright.' );

# Make sure it shows up in the drafts list and not the archive.
ok( ( any { $_->id == $rsa->id } $c->model( 'RSA' )->drafts ),
    'RSA is in drafts' );
ok( ( not any { $_->id == $rsa->id } $c->model( 'RSA' )->archive ),
    'RSA is not in archive' );

# Update some fields.  Again we need an HTML form.
$form = HTML::FormFu->new;
$form->load_config_file( "$FindBin::Bin/../root/forms/dca/rsa.yml" );
$form->process( {
    generalRecordsDescription => 'Photos of Spinal Tap drummers.',
    activityLogNumber => '69,105',
    transferDate => '2010-02-14',
    is_final => 1,
} );

ok( $rsa->update_from_form( $form ), 'Updated the RSA.' );

# Check the fields again.
$rsa = $c->model( 'RSA' )->find( $rsa->id );
is_deeply( $rsa->sipCreationAndTransfer, [ 'label_box', 'create_inventory' ],
    'Checked sipCreationAndTransfer.' );
is( $rsa->generalRecordsDescription, 'Photos of Spinal Tap drummers.',
    'Checked generalRecordsDescription.' );
is_deeply( $rsa->formatType, [ 'photographic_prints', 'digital_media' ],
    'Checked formatType.' );
is_deeply( $rsa->activityLogNumber, [ '69,105' ],
    'Checked activityLogNumber.' );

# Make sure it shows up in the archive list and not in drafts.
ok( ( any { $_->id == $rsa->id } $c->model( 'RSA' )->archive ),
    'RSA is in archive' );
ok( ( not any { $_->id == $rsa->id } $c->model( 'RSA' )->drafts ),
    'RSA is not in drafts' );

# Validate the XML file against the XML Schema.
my $id = $rsa->id;
my $path = "$FindBin::Bin/run/staging/$id";
my $xml_file = "$path/$id.xml";
my $doc = XML::LibXML->new->parse_file( $xml_file );
ok( $doc, 'RSA is well-formed XML' );
my $schema_file = "$FindBin::Bin/../../schema/rsa.xsd";
my $schema = XML::LibXML::Schema->new( location => $schema_file );
my $invalid = eval { $schema->validate( $doc ) };
is( $invalid, 0, 'RSA is valid XML' ) or diag( $@ );

# Delete it and make sure it was deleted.
$rsa->delete;
eval { $c->model( 'RSA' )->find( $rsa->id ) };
ok( $@, 'Did not find deleted RSA' );
ok( ! -e $path, 'Path was deleted' );
