package HTML::FormFu::Element::RepeatableSelect;

use strict;
use base 'HTML::FormFu::Element::Select';
use MRO::Compat;
use mro 'c3';
use Scalar::Util qw( reftype );

sub prepare_attrs {
    my ( $self, $render ) = @_;

    my $submitted = $self->form->submitted;
    my $default   = $self->default;

    my $value
        = defined $self->name
        ? $self->get_nested_hash_value( $self->form->input, $self->nested_name )
        : undef;

    my $i = $self->_index_in_group;
    if ( defined $i ) {
        if ( ( reftype($value) || '' ) eq 'ARRAY' ) {
            $value = $value->[ $i ];
        }
        if ( ( reftype($default) || '' ) eq 'ARRAY' ) {
            $default = $default->[ $i ];
        }
    }

    if ( !$submitted && defined $default ) {
        for my $deflator ( @{ $self->_deflators } ) {
            $default = $deflator->process($default);
        }
    }

    for my $option ( @{ $render->{options} } ) {
        if ( exists $option->{group} ) {
            for my $item ( @{ $option->{group} } ) {
                $self->_prepare_attrs( $submitted, $value, $default, $item );
            }
        }
        else {
            $self->_prepare_attrs( $submitted, $value, $default, $option );
        }
    }

    # Skip the parent method.
    $self->HTML::FormFu::Element::_Input::prepare_attrs($render);

    return;
}

sub _index_in_group {
    my ( $self ) = @_;

    my $elems = $self->form->get_fields({ nested_name => $self->nested_name });
    if ( $#$elems ) {
        # There are multiple fields with the same name; assume
        # none are multi-value fields, i.e. only one selected
        # option per field.  (Otherwise it might be ambiguous
        # which option came from which field.)
        for ( 0 .. @$elems - 1 ) {
            if ( $self == $elems->[$_] ) {
                return $_;
            }
        }
    }
}

sub type { return 'Select'; }

1;

__END__

=head1 NAME

HTML::FormFu::Element::RepeatableSelect - Select form field that can be inside a Repeatable

=head1 METHODS

=over

=item prepare_attrs

Override prepare_attrs of Select (actually defined in _Group) to fix
the behavior when there are multiple fields with the same name.  In
this case, the value and default are arrays of values that correspond
to the fields, so we have to pick out the one that corresponds to this
field.

=item type

Returns 'Select' rather than 'RepeatableSelect' so that the HTML
class comes out the same as a non-patched select.

=back

=head1 SEE ALSO

Is a sub-class of, and inherits methods from 
L<HTML::FormFu::Element::Select>, 
L<HTML::FormFu::Element::_Group>, 
L<HTML::FormFu::Element::_Input>, 
L<HTML::FormFu::Element::_Field>, 
L<HTML::FormFu::Element>

L<HTML::FormFu>

=head1 AUTHOR

Doug Orleans, C<dougorleans@gmail.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.
