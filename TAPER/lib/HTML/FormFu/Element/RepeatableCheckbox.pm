package HTML::FormFu::Element::RepeatableCheckbox;

use strict;
use base 'HTML::FormFu::Element::Checkbox';
use Class::C3;
use List::MoreUtils qw( any );

use HTML::FormFu::Constants qw( $EMPTY_STR );

sub prepare_attrs {
    my ( $self, $render ) = @_;

    my $form      = $self->form;
    my $submitted = $form->submitted;
    my $default   = $self->default;
    my $original  = $self->value;

    my $value
        = defined $self->name
        ? $self->get_nested_hash_value( $form->input, $self->nested_name )
        : undef;

    if (   $submitted
        && defined $value
        && defined $original
        && (ref $value eq 'ARRAY'
	    ? any { $_ eq $original } @$value
	    : $value eq $original ) )
    {
        $render->{attributes}{checked} = 'checked';
    }
    elsif ($submitted
        && $self->retain_default
        && ( !defined $value || $value eq $EMPTY_STR ))
    {
        $render->{attributes}{checked} = 'checked';
    }
    elsif ($submitted && !$self->retain_default) {
        delete $render->{attributes}{checked};
    }
    elsif ( defined $default && defined $original
	    && (ref $default eq 'ARRAY'
		? any { $_ eq $original } @$default
		: $default eq $original ) )
    {
        $render->{attributes}{checked} = 'checked';
    }

    # Skip the parent method.
    $self->HTML::FormFu::Element::_Input::prepare_attrs($render);

    return;
}

sub type { return 'Checkbox'; }

1;

__END__

=head1 NAME

HTML::FormFu::Element::RepeatableCheckbox - Checkbox form field that can be inside a Repeatable

=head1 METHODS

=over

=item prepare_attrs

Override Checkbox prepare_attrs to fix the behavior when this field's
value and/or default is an array.  In these cases, a checkbox is
considered checked iff its value is any member of the form's submitted
value array or default array.  (The array is assumed to be a set of
unique values, otherwise there's no way to tell which boxes should be
checked.)

=item type

Returns 'Checkbox' rather than 'RepeatableCheckbox' so that the HTML
class comes out the same as a non-patched checkbox.

=back

=head1 SEE ALSO

Is a sub-class of, and inherits methods from 
L<HTML::FormFu::Element::Checkbox>, 
L<HTML::FormFu::Element::_Input>, 
L<HTML::FormFu::Element::_Field>, 
L<HTML::FormFu::Element>

L<HTML::FormFu>

=head1 AUTHOR

Doug Orleans, C<dougorleans@gmail.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.
