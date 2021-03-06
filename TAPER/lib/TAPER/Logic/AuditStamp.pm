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

package TAPER::Logic::AuditStamp;

use warnings;
use strict;
use English;
use Moose;
use Moose::Util::TypeConstraints;
use Carp qw( croak );
use Scalar::Util;

has 'timestamp'  => ( is => 'rw', isa => 'DateTime',
                      required => 1, coerce => 1 );
has 'by'  => ( is => 'rw', isa => 'Str', required => 1 );

1;

=head1 NAME

TAPER::Logic::AuditStamp - Submission agreement audit-section timestamps

=head1 DESCRIPTION

Simple object representation of a timestamp and a byline, as found in
the C<audit> element of a submission agreement XML file.

=head1 METHODS

=head2 Class Methods

=over

=item new ( $creation_args_hashref )

Typical Moose-style object constructor.

=back

=head2 Object Methods

The only methods this class offers are accessors, and they're called
in typical Perl style: they always return the object's like-named
attribute, and if called with an argument, then they set the attribute
to that argument value first. (If the argument value is inavlid for
that attribute, it'll throw an exception.)

=over

=item timestamp

Returns a DateTime object representing the date part of this timestamp.

Can be set with either a DateTime object, or a string of format
YYYY-MM-DD.

=item by

Returns, and accepts, a string representing the person who made
whatever modification this timestamp represents.

=back

=head1 AUTHOR

Jason McIntosh, Appleseed Software Consulting <jmac@appleseed-sc.com>

=head1 COPYRIGHT

Copyright (c) 2009 by Tufts University.

=cut
