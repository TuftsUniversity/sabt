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

package TAPERTest;
use strict;
use warnings;

use FindBin;

$ENV{TAPER_SITE_CONFIG} = "$FindBin::Bin/conf/taper.conf";
$ENV{TAPER_DEBUG}       = 0;

use DateTime;
use DateTime::Format::MySQL;

use Carp qw(croak);
use English;

use File::Path qw( remove_tree make_path );
use File::Copy qw( copy );

use TAPER::Schema;

my $now_dt = DateTime->now;
my $future_dt = $now_dt->add(hours => 1);

sub init_schema {
    my $self = shift;
    my %args = @_;

    my $db_dir  = "$FindBin::Bin/db";
    my $db_file = "$db_dir/taper.db";

    if (-e $db_file) {
        unlink $db_file
            or croak("Couldn't unlink $db_file: $OS_ERROR");
    }

    remove_tree( TAPER->config->{rsa_staging_directory},
		 TAPER->config->{ssa_directory} );

    my $schema = TAPER::Schema->
        connect("dbi:SQLite:$db_file", '', '',);

    $schema->deploy;
    $self->populate_schema( $schema );

    return $schema;
}

sub populate_schema {
    my $self   = shift;
    my $schema = shift;

    $schema->populate(
        'User',
        [
            [qw/ id username first_name last_name is_dca /],
            [1, 'alice', 'Alice', 'Liddell', 1 ],
            [2, 'bob', 'Bob', 'Dobbs', 0],
        ]
    );

    $schema->populate(
        'Office',
        [
            [ qw/ id name / ],
            [ 1, 'Dept of Widget Studies'],
	    [ 2, 'Dept of Sprocket Science'],
	    [ 3, 'Office of the President'],
	    [ 4, 'Office Number Four'],
	    [ 5, 'Some Other Department'],
	    [ 6, 'There Is No Six'],
	    [ 7, 'Department Seven'],
        ]
    );

    $schema->populate(
        'Role',
        [
            [ qw/ id name / ],
            [ 1, 'DCA Staff'],
        ]
    );

    $schema->populate(
        'UserOffice',
        [
            [ qw/ user office active / ],
            [ 1, 1, 1 ],
            [ 2, 1, 1 ],
            [ 2, 2, 0 ],
            [ 2, 6, 0 ],
        ]
    );

    $schema->populate(
        'UserRole',
        [
            [ qw/ user role / ],
            [ 1, 1 ],
        ]
    );

    my $ssa_dir = TAPER->config->{ssa_directory};
    make_path( $ssa_dir );
    my $ssa_path = "$ssa_dir/1.xml";
    copy( "$FindBin::Bin/ssa/widgets.xml", $ssa_path );

    $schema->populate(
        'Ssa',
        [
            [ qw/ id path office / ],
            [ 1, $ssa_path, 1 ],
        ]
    );

    my $rsa_dir = TAPER->config->{rsa_staging_directory} . '/1';
    make_path( $rsa_dir );
    my $rsa_path = "$rsa_dir/1.xml";
    copy( "$FindBin::Bin/rsa/widgets.xml", $rsa_path );
    make_path( "$rsa_dir/inventory" );

    $schema->populate(
        'Rsa',
        [
            [ qw/ id path ssa is_final / ],
            [ 1, $rsa_path, 1, 0 ],
        ]
    );

    # TO DO: inventory

}

sub login {
    my $self = shift;
    my ( $username ) = @_;

    my $mech = Test::WWW::Mechanize::Catalyst->new;
    $mech->get( '/auth/login' );
    $mech->submit_form(
	with_fields => {
	    username => $username,
	    password => 'password',
	    login_form_submit => 'Log in',
	}
    );
    return $mech;
}

1;

__END__

=head1 NAME

TAPERTest

=head1 SYNOPSIS

    use lib qw(t/lib);
    use TAPERTest;
    use Test::More;

    my $schema = TAPERTest->init_schema();

    # To test the Web interface:
    use Test::WWW::Mechanize::Catalyst 'TAPER';
    my $mech = TAPERTest->login( 'alice' );  # use 'bob' for non-DCA

=head1 DESCRIPTION

This module provides the basic utilities to write tests against
TAPER. Shamelessly stolen from DBICTest in the DBIx::Class test
suite. (Actually it's stolen from a consulting colleague of Jason's,
who stole it in turn from DBIC...)

=head1 METHODS

=head2 init_schema

    my $schema = TAPERTest->init_schema();

This method removes the test SQLite database in t/db/taper.db
and then creates a new, empty database.  It also removes any
files in the XML directories.

This method calls $schema->deploy() to create the db schema based on
the DBIC schema, and populate_schema() to insert default data.

=head2 populate_schema

  TAPERTest->populate_schema( $schema );

After you deploy your schema you can use this method to populate
the tables and XML directories with test data.

=head2 login

  TAPERTest->login( $username );

This method creates a Test::WWW::Mechanize object, uses it to log into
TAPER, and returns it.
