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

package TAPER::Schema::UserRole;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("user_role");
__PACKAGE__->add_columns(
  "user",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "role",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
);
__PACKAGE__->belongs_to("user", "TAPER::Schema::User", { id => "user" });
__PACKAGE__->belongs_to("role", "TAPER::Schema::Role", { id => "role" });


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-03-10 23:08:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QpLKln5Yp1XLujuYjEMlTg


# You can replace this text with custom content, and it will be preserved on regeneration
1;

=head1 NAME

TAPER::Schema::UserRole - DBIC Schema for TAPER user-role relationships

=head1 DESCRIPTION

This is a simple DBIC schema module that maps the TAPER 'user_role' table
into Perl objects. It is a subclass of DBIx::Class; see also.

I<It is not currently used by anything.> Currently, all user
authorization is simply a matter of how the C<is_dca>
column of the relevant user record is set.

=head1 METHODS

=head2 Accessors

These accessors are called in typical Perl style: they always return
the object's like-named attribute, and if called with an argument,
then they set the attribute to that argument value first. (If the
argument value is inavlid for that attribute, it'll throw an
exception.)

=over

=item user

The associated user (see L<TAPER::Schema::User>.)

=item role

The associated role (see L<TAPER::Schema::Role>.)

=back

=head1 AUTHOR

Jason McIntosh <jmac@appleseed-sc.com>

=head1 COPYRIGHT

Copyright (c) 2009 by Tufts University.

