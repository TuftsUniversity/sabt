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

package TAPER::Model::TAPERDB;

use strict;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'TAPER::Schema',
    connect_info => [
        'dbi:mysql:taper',
        'root',
        
    ],
);

=head1 NAME

TAPER::Model::TAPERDB - Catalyst DBIC Schema Model

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<TAPER::Schema>

This just sets up database model relationships in the usual
Catalyst/DBIC ways. Seek ye elsewhere for more information about that.

=head1 SEE ALSO

Here are the table-tied schema classes that TAPER makes use of:

=over

=item TAPER::Schema::User

TAPER users.

=item TAPER::Schema::Rsa

The database-specific part of regular submission agreements. See
L<TAPER::Logic::RSA> for a more complete abstarction later to RSAs.

=item TAPER::Schema::Ssa

The database-specific part of standing submission agreements. See
L<TAPER::Logic::SSA> for a more complete abstarction later to SSAs.

=item TAPER::Schema::Office

Tufts University Offices (and other groups) that TAPER recognizes.

=item TAPER::Schema::UserOffice

Many-to-many links between users and offices.

=item TAPER::Schema::Role

I<Not currently used.> TAPER authorization roles. 

=item TAPER::Schema::UserRole

I<Not currently used.> Many-to-many links between users and roles. 

=back

=head1 AUTHOR

Jason McIntosh, Appleseed Software Consulting <jmac@appleseed-sc.com>

=head1 COPYRIGHT

Copyright (c) 2009 by Tufts University.

=cut

1;
