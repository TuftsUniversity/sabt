#!/usr/bin/perl

use warnings;
use strict;

use FindBin;

use XML::LibXML;

my ( $sa, $file ) = @ARGV;

unless ( $file ) {
    warn "Usage: $0 ssa|rsa [file.xml]\n";
    exit;
}

my $schema_file = "$FindBin::Bin/$sa.xsd";

unless ( -e $schema_file ) {
    die "ERROR: Can't find a schema file at $schema_file.\n";
}

print "Loading document\n";
my $doc = XML::LibXML->new->parse_file( $file );
print "Done.\n";
print "Loading schema\n";
my $schema = XML::LibXML::Schema->new( location => $schema_file );
print "Done\n";
print "Validating document\n";
$schema->validate( $doc );
