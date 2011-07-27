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

package HTML::FormFu::Element::AllOrNoneDate;

use strict;
use warnings;
use parent 'HTML::FormFu::Element::ShowComponentErrorsDate';
use Class::C3;

sub _add_day {
    my $self = shift;

    $self->next::method( @_ );

    my $day_name = $self->_build_name( 'day' );
    my $month_name = $self->_build_name( 'month' );
    my $year_name = $self->_build_name( 'year' );

    my $day = $self->get_element( $day_name );
    $day->constraint( {
	type => 'AllOrNone',
	others => [ $month_name, $year_name ],
	message => 'This field is required',
    } );
}

1;

__END__

=head1 NAME

HTML::FormFu::Element::AllOrNoneDate

=head1 DESCRIPTION

A subclass of the Date form field that requires that either all its
components are selected or none of them are selected.  If some are
selected but not all, the unselected components will have a "This
field is required" error attached.

=head1 AUTHOR

Doug Orleans, Appleseed Software Consulting C<dougo@appleseed-sc.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself
