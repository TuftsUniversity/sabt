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

package TAPER::Schema::Rsa;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("rsa");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "path",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 64 },
  "ssa",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "is_final",
  { data_type => "TINYINT", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to("ssa", "TAPER::Schema::Ssa", { id => "ssa" });


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-03-10 23:08:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:m5qU0Cnt/V+MHO+xBb8vNw

use File::Spec;

sub absolute_path {
    my $self = shift;

    return File::Spec->rel2abs( $self->path,
				TAPER->config->{rsa_staging_directory} );
}

1;

=head1 NAME

TAPER::Schema::Rsa - DBIC Schema for regular submission agreements

=head1 DESCRIPTION

This is a simple DBIC schema module that maps the TAPER 'rsa' table
into Perl objects. It is a subclass of DBIx::Class; see also.

Objects of this class relate only to The database-specific part of
regular submission agreements. See L<TAPER::Logic::RSA> for a more
complete abstarction later to RSAs.

=head1 METHODS

=head2 Accessors

These accessors are called in typical Perl style: they always return
the object's like-named attribute, and if called with an argument,
then they set the attribute to that argument value first. (If the
argument value is inavlid for that attribute, it'll throw an
exception.)

=over

=item id

This RSA's database ID.

=item path

The filesystem path of this RSA's XML file.  If the path is relative,
it is relative to the path specified by the rsa_staging_directory
configuration setting (in taper.conf).

=item absolute_path

I<Read-only.> The absolute filesystem path of this RSA's XML file.

=item ssa

The SSA that this RSA is associated with. (See L<TAPER::Schema::SSA>.)

=item is_final

If set to a true value, then this is RSA has been marked as complete
by DCA staff. Otherwise, it's just a draft copy, and likely
incomplete, having received only enduser attention.

=back

=head1 AUTHOR

Jason McIntosh <jmac@appleseed-sc.com>
Doug Orleans <dougo@appleseed-sc.com>

=head1 COPYRIGHT

Copyright (c) 2009-2010 by Tufts University.

