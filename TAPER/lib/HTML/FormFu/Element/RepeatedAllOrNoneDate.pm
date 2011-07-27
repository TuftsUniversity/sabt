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

package HTML::FormFu::Element::RepeatedAllOrNoneDate;

use strict;
use warnings;
use parent 'HTML::FormFu::Element::AllOrNoneDate';
use Class::C3;
use Scalar::Util qw( blessed );
use List::MoreUtils qw( all );
use HTML::FormFu::Element::Multi;

# Copied from Date with section added.
sub _date_defaults {
    my ($self) = @_;

    my $default;

    if ( defined( $default = $self->default_natural ) ) {
        my $parser = DateTime::Format::Natural->new;
        $default = $parser->parse_datetime($default);
    }
    elsif ( defined( $default = $self->default ) ) {

	# ADDED
	if ( ref( $default ) && ref( $default ) eq 'ARRAY' ) {
	    my $elems = $self->form->get_fields({ nested_name => $self->nested_name });
	    for ( 0 .. @$elems - 1 ) {
		if ( $self == $elems->[$_] ) {
		    $default = $default->[$_];
		    last;
		}
	    }
	}

        my $is_blessed = blessed($default);

        if ( !$is_blessed || ( $is_blessed && !$default->isa('DateTime') ) ) {
            my $builder = DateTime::Format::Builder->new;
            $builder->parser( { strptime => $self->strftime } );

            $default = $builder->parse_datetime($default);
        }
    }

    if ( defined $default ) {
        for my $field ( @{ $self->field_order } ) {
            $self->$field->{default} = $default->$field;
        }
    }
}

# Copied from Date with two sections added.
sub process_input {
    my ( $self, $input ) = @_;

    my %value;

    my @order = @{ $self->field_order };

    for my $i ( 0 .. $#order ) {
        my $field = $order[$i];

        my $name = $self->_elements->[$i]->nested_name;

	my $val = $self->get_nested_hash_value( $input, $name );

	# ADDED
	if ( defined( $val ) && ref( $val ) && ref( $val ) eq 'ARRAY' ) {
	    my $elems = $self->form->get_fields({ nested_name => $self->nested_name });
	    for ( 0 .. @$elems - 1 ) {
		if ( $self == $elems->[$_] ) {
		    $val = $val->[$_];
		    last;
		}
	    }
	}

        $value{$field} = $val;
    }

    if ( ( all {defined} values %value )
        && all {length} values %value )
    {
        my $dt;

        eval {
            $dt = DateTime->new( map { $_, $value{$_} } keys %value );
        };

        my $value;

        if ($@) {
            $value = $self->strftime;
        }
        else {
            $value = $dt->strftime( $self->strftime );
        }

	# ADDED
	my $vals = $self->get_nested_hash_value( $input, $self->nested_name );
	my @vals;
	if ( defined( $vals ) ) {
	    @vals = @$vals;
	}
	push @vals, $value;

        $self->set_nested_hash_value( $input, $self->nested_name, \@vals );
    }

    # Skip the parent method.
    return $self->HTML::FormFu::Element::Multi::process_input($input);
}

1;

__END__

=head1 NAME

HTML::FormFu::Element::RepeatedAllOrNoneDate

=head1 DESCRIPTION

A subclass of the AllOrNoneDate form field that behaves correctly when
inside a Repeatable.

=head1 METHODS

=over

=item _date_defaults

If the default value is an array, set the component default values to arrays.

=item process_input

If the component values are arrays, set the field value to an array.

=back

=head1 AUTHOR

Doug Orleans, Appleseed Software Consulting C<dougo@appleseed-sc.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself
