package HTML::FormFu::Element::RequiredDate;

use strict;
use warnings;
use parent 'HTML::FormFu::Element::ShowComponentErrorsDate';
use Class::C3;

sub _add_elements {
    my $self = shift;

    $self->next::method( @_ );

    for my $elem ( @{ $self->_elements } ) {
	$elem->constraint( 'Required' );
    }
}

1;

__END__

=head1 NAME

HTML::FormFu::Element::RequiredDate

=head1 DESCRIPTION

A subclass of the Date form field that requires that all its
components are selected.  The unselected components will have a "This
field is required" error attached.

=head1 AUTHOR

Doug Orleans, Appleseed Software Consulting C<dougo@appleseed-sc.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself
