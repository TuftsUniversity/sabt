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

package HTML::FormFu::Element::RepeatableFieldset;

use strict;
use warnings;
use parent 'HTML::FormFu::Element::Fieldset';
use Class::C3;

sub new {
    my $self = shift->next::method( @_ );

    $self->add_attrs( { class => 'repeatable' } );

    $self->element_containers_tag( 'span' );

    return $self;
}

__PACKAGE__->mk_item_accessors( qw(
        _processed
        preamble
        element_containers_tag
) );

sub process {
    my $self = shift;

    if ( !$self->_processed ) {

	my $name = $self->name;
	my $elements = $self->_elements;

	$self->_elements( [] );

	$self->element( {
	    type => 'Hidden',
	    name => "${name}_counter",
	    id => "${name}_counter",
	    value => 1,
        } );

	if ( $self->preamble ) {
	    $self->elements( $self->preamble );
	}

	my $block = $self->element( {
	    type => 'Block',
	    id => $name,
        } );

	my $repeatable = $block->element( {
	    type => 'Repeatable',
	    name => "${name}_repeatable",
	    increment_field_names => 0,
	    counter_name => "${name}_counter",
        } );

	if ( @$elements ) {
	    $repeatable->_elements( $elements );
	    for my $element ( @$elements ) {
		$element->parent( $repeatable );
		$element->container_tag( $self->element_containers_tag );
	    }
	} else {
	    $repeatable->element( {
		type => 'Text',
		container_tag => $self->element_containers_tag,
		name => $name,
            } );
	}

	$repeatable->element( {
	    type => 'Button',
	    container_tag => $self->element_containers_tag,
	    id => "remove_${name}_button",
	    value => '-',
	    attrs => { onclick => "remove_field( this )" },
        } );

	$self->element( {
	    type => 'Button',
	    id => "add_${name}_button",
	    value => '+',
	    attrs => { onclick => "add_field( '${name}' )" },
        } ) ;

	$self->_processed( 1 );
    }

    return $self->next::method( @_ );
}

sub repeat {
    my $self = shift;
    my ( $count ) = @_;
    
    my $name = $self->name;
    my $rep = $self->get_all_element( "${name}_repeatable" );
    $rep->repeat( $count );
    my $counter = $self->get_field( $rep->counter_name );
    $counter->value( $count );
}

=head1 NAME

HTML::FormFu::Element::RepeatableFieldset

=head1 DESCRIPTION

A Fieldset that contains a Repeatable set of fields, which can be
dynamically added or removed with Javascript buttons.

=head1 METHODS

=over

=item new

Sets the fieldset class to 'repeatable'.

=item process

If this is the first time the fieldset has been processed, moves all
its children into a Repeatable and sets up buttons and other
machinery.  If it has no children, a single Text child is added, with
the same name as the fieldset.

=item preamble

If a preamble is set with this method, it will be used to create an
element or elements (using the L<HTML::FormFu/element> method) to be
placed before the Repeatable when the fieldset is processed.

=item repeat ( $count )

Repeat the repeatable field and set its counter.  Use this only when
initially populating the form; once the form has been submitted, the
field will automatically be repeated as necessary.

=back

=head1 AUTHOR

Doug Orleans, Appleseed Software Consulting <dougo@appleseed-sc.com>

=head1 COPYRIGHT

Copyright (c) 2009 by Tufts University.

=cut

1;
