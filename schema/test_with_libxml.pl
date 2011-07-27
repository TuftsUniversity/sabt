#!/usr/bin/perl
#
# COPYRIGHT:
#
# Copyright 2010, 2011 Tufts University.
#
#
# FUNDING:
#
# The development of the TAPER software suite was funded by the
# National Historic Publications and Records Commission (NHPRC).
# Grant number RE10005-08.
#
#
# LICENSE:
#
# This file is part of the TAPER software suite.
#
# The TAPER software suite is free software: you can redistribute
# it and/or modify it under the terms of the GNU Affero General
# Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later
# version.
#
# The TAPER software suite is distributed in the hope that it will
# be useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public
# License along with the TAPER software suite.  If not, see
# <http://www.gnu.org/licenses/>.
#


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
