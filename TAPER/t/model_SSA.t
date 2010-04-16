#!/usr/bin/perl

use strict;
use warnings;
use Test::More qw( no_plan );
use List::MoreUtils qw( any );
use XML::LibXML;

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

# In order to create an SSA, we need an HTML form.

my $form = HTML::FormFu->new;
$form->load_config_file( "$FindBin::Bin/../root/forms/dca/ssa.yml" );
$form->process( {
    recordsCreator_id =>  '123',
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
} );

# Create the SSA.
ok( my $ssa = $c->model( 'SSA' )->create_from_form( $form ),
    'Created SSA.' );

# Check some fields.
is( $ssa->db_record->office->id, 1,
    'Checked office_id.' );
is( $ssa->access->[0], 'Category 42',
    'Checked access.' );
is( $ssa->generalRecordsDescription, 'This is the test SSA number 1.',
    'Checked generalRecordsDescription.' );
is( $ssa->warrantToCollect->[0], 'University Records Policy',
    'Checked warrantToCollect.' );

# Lookup the SSA by its id.
ok( $ssa = $c->model( 'SSA' )->find( $ssa->id ), 'Found the SSA.' );

# Check the fields again.
is( $ssa->access->[0], 'Category 42',
    'Checked access.' );
is( $ssa->generalRecordsDescription, 'This is the test SSA number 1.',
    'Checked generalRecordsDescription.' );
is( $ssa->warrantToCollect->[0], 'University Records Policy',
    'Checked warrantToCollect.' );

# Check that the SSA appears in the right office list.
ok( ( any { $_->id == $ssa->id } $c->model( 'SSA' )->all_for_office( 1 ) ),
    'SSA is in office 1' );
ok( ( not any { $_->id == $ssa->id } $c->model( 'SSA' )->all_for_office( 2 ) ),
    'SSA is not in office 2' );

# Update some fields.  Again we need an HTML form.
$form = HTML::FormFu->new;
$form->load_config_file( "$FindBin::Bin/../root/forms/dca/ssa.yml" );
$form->process( {
    office_id => 2,
    access => 'Front 242',
    generalRecordsDescription => 'This is the edited desc.',
    warrantToCollect => 'dead or alive',
} );

ok( $ssa->update_from_form( $form ), 'Updated the SSA.' );

# Check the updated fields.
$ssa = $c->model( 'SSA' )->find( $ssa->id );
is( $ssa->access->[0], 'Front 242',
    'Checked access.' );
is( $ssa->generalRecordsDescription, 'This is the edited desc.',
    'Checked generalRecordsDescription.' );
is( $ssa->warrantToCollect->[0], 'dead or alive',
    'Checked warrantToCollect.' );

# Check that the SSA appears in a different office list.
ok( ( not any { $_->id == $ssa->id } $c->model( 'SSA' )->all_for_office( 1 ) ),
    'SSA is not in office 1' );
ok( ( any { $_->id == $ssa->id } $c->model( 'SSA' )->all_for_office( 2 ) ),
    'SSA is in office 2' );

# Validate the XML file against the XML Schema.
my $id = $ssa->id;
my $xml_file = "$FindBin::Bin/run/ssa/$id.xml";
my $doc = XML::LibXML->new->parse_file( $xml_file );
ok( $doc, 'SSA is well-formed XML' );
my $schema_file = "$FindBin::Bin/../../schema/ssa.xsd";
my $schema = XML::LibXML::Schema->new( location => $schema_file );
my $invalid = eval { $schema->validate( $doc ) };
is( $invalid, 0, 'SSA is valid XML' ) or diag( $@ );
