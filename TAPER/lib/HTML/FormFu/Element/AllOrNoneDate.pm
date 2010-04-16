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
