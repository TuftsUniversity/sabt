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

package HTML::FormFu::Element::ShowComponentErrorsDate;

use strict;
use warnings;
use parent 'HTML::FormFu::Element::Date';
use Class::C3;

use HTML::FormFu::Util qw(
    process_attrs remove_xml_attribute _parse_args _filter_components
);

sub type {
    return 'Date';
}

sub _add_elements {
    my $self = shift;

    $self->next::method( @_ );

    for my $elem ( @{ $self->_elements } ) {
	$elem->container_tag( 'span ' );
    }
}

# Copied from HTML::FormFu::Element::_Field.pm
sub get_errors {
    my $self = shift;
    my %args = _parse_args(@_);

    my @x = @{ $self->_errors };

    _filter_components( \%args, \@x );

    if ( !$args{forced} ) {
        @x = grep { !$_->forced } @x;
    }

    return \@x;
}

# Copied from HTML::FormFu::Element::Multi.pm, with two lines added.
sub string {
    my ( $self, $args ) = @_;

    $args ||= {};

    my $render
        = exists $args->{render_data}
        ? $args->{render_data}
        : $self->render_data_non_recursive;

    # field wrapper template - start

    my $html = $self->_string_field_start($render);

    # multi template

    $html .= sprintf "<span%s>\n", process_attrs( $render->{attributes} );

    for my $elem ( @{ $self->get_elements } ) {

        my $render = $elem->render_data;

        next if !defined $render;

	# ADDED
	$html .= $elem->_string_field_start( $render );

        if ( $elem->reverse_multi ) {
            $html .= $elem->_string_field($render);

            if ( defined $elem->label ) {
                $html .= sprintf "\n%s", $elem->_string_label($render);
            }
        }
        else {
            if ( defined $elem->label ) {
                $html .= $elem->_string_label($render) . "\n";
            }

            $html .= $elem->_string_field($render);
        }

	# ADDED
	$html .= $elem->_string_field_end( $render );

        $html .= "\n";
    }

    $html .= "</span>";

    # field wrapper template - end

    $html .= $self->_string_field_end($render);

    return $html;
}

1;

__END__

=head1 NAME

HTML::FormFu::Element::ShowComponentErrorsDate

=head1 DESCRIPTION

A subclass of the Date form field that shows errors attached to the
Date components rather than showing them on the Date field as a whole.

=head1 METHODS

=over

=item type

Returns 'Date' so that the CSS class of the container will be 'date'.

=item get_errors

Returns only the errors on the Date field itself, rather than
including its component errors.

=item string

Includes the errors on each component, if any.

=back

=head1 AUTHOR

Doug Orleans, Appleseed Software Consulting C<dougo@appleseed-sc.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.
