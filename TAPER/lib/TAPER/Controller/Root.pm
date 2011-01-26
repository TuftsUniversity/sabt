package TAPER::Controller::Root;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use Scalar::Util qw( looks_like_number );
use List::MoreUtils qw( each_array all any );

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

sub index :Path :Args(0) {
}

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
    
}

sub end : ActionClass('RenderView') {}

sub preservation_rules :Local :Args(0) {
    my $self = shift;
    my ( $c ) = @_;

    $c->stash->{rules} =
        [ $c->model( 'TAPERDB::PreservationRule' )->search( undef, {
            order_by => 'number' } ) ];
}

sub validate_nonempty_repeatable : Private {
    my $self = shift;
    my ( $c, @names ) = @_;

    my $form = $c->stash->{form};

    for my $name ( @names ) {
	if ( all { $_ eq '' } $form->param_list( $name ) ) {
	    _mk_error( $form->get_field( $name ), 'Required' );
	}
    }
}

sub validate_producers : Private {
    my $self = shift;
    my ( $c, @names ) = @_;

    my $form = $c->stash->{form};

    for my $name ( @names ) {
	if ( all { $_ eq '' }
	     $form->param_list( "${name}_id" ),
	     $form->param_list( "${name}_email" ),
	     $form->param_list( "${name}_name") )
	{
	    my $error = _mk_error( $form->get_field( "${name}_name" ),
				   'Required' );
	    $error->message( 'At least one name, ID, or email address is required' );
	}
    }
}

sub validate_extents : Private {
    my $self = shift;
    my ( $c ) = @_;

    my $form = $c->stash->{form};
    my $value_fields = $form->get_fields( 'extent_value' );
    my $units_fields = $form->get_fields( 'extent_units' );
    my @value_params = $form->param_list( 'extent_value' );
    my @units_params = $form->param_list( 'extent_units' );
    my $ea = each_array( @$value_fields, @$units_fields,
			 @value_params, @units_params );
    my $empty = 1;

    while ( my ( $value_field, $units_field, $value, $units ) = $ea->() ) {
	if ( $value ne '' ) {
	    $empty = 0;
	    if ( !looks_like_number( $value ) ) {
		_mk_error( $value_field, 'Number' );
	    }
	    if ( $units eq '' ) {
		_mk_error( $units_field, 'Required' );
	    }
	} elsif ( $units ne '' ) {
	    $empty = 0;
	    _mk_error( $value_field, 'Required' );
	}
    }

    if ( $empty ) {
	_mk_error( $value_fields->[0], 'Required' );
	_mk_error( $units_fields->[0], 'Required' );
    }
}

sub validate_dateSpans : Private {
    my $self = shift;
    my ( $c ) = @_;

    my $form = $c->stash->{form};
    my $start_fields = $form->get_fields( 'dateSpan_start' );
    my $end_fields   = $form->get_fields( 'dateSpan_end' );
    my @start_params = $form->param_list( 'dateSpan_start' );
    my @end_params   = $form->param_list( 'dateSpan_end' );

    my $ea = each_array( @$start_fields, @$end_fields,
			 @start_params, @end_params );
    my $empty = 1;
    my @spans;

    while ( my ( $start_field, $end_field, $start, $end ) = $ea->() ) {
	my ( $start_valid, $end_valid );
	if ( $start ne '' ) {
	    $empty = 0;
	    $start_valid = _validate_year( $start, $start_field );
	    if ( $end eq '' ) {
		_mk_error( $end_field, 'Required' );
	    }
	}
	if ( $end ne '' ) {
	    $empty = 0;
	    $end_valid = _validate_year( $end, $end_field );
	    if ( $start eq '' ) {
		_mk_error( $start_field, 'Required' );
	    }
	}
	if ( $start_valid && $end_valid ) {
	    if ( $start > $end ) {
		my $error = _mk_error( $end_field, 'Ordered' );
		$error->message( 'Must not precede starting year' );
	    } elsif ( any { _overlap( $_, [ $start, $end ] ) } @spans ) {
		my $error = _mk_error( $start_field, 'Overlap' );
		$error->message( 'Must not overlap other date spans' );
	    } else {
		push @spans, [ $start, $end ];
	    }
	}
    }

    if ( $empty ) {
	_mk_error( $start_fields->[0], 'Required' );
	_mk_error( $end_fields->[0],   'Required' );
    }
}

sub _validate_year {
    my ( $year, $field ) = @_;

    return 1 if ( $year =~ /^[1-9][0-9]{3}$/ );

    my $error = _mk_error( $field, 'Integer' );
    $error->message( 'Must be four-digit integer' );
    return 0;
}

sub _overlap {
    my ( $span1, $span2 ) = @_;

    # Two date spans overlap if they have more than one year in common.
    # overlap( [2003,2005], [2004,2006] ) == 1
    # overlap( [2003,2005], [2005,2006] ) == 0
    # In other words, they do not overlap if the start of one is
    # greater than or equal to the end of the other.
    # Equivalently, they do overlap if the start of each is strictly
    # less than the end of the other.
    return $span1->[0] < $span2->[1] && $span2->[0] < $span1->[1];
}

sub _mk_error {
    my ( $parent, $type ) = @_;

    my $error = HTML::FormFu::Exception::Constraint->new;
    my $processor = HTML::FormFu::Processor->new( { type => $type } );
    $error->parent( $parent );
    $error->processor( $processor );
    $parent->add_error( $error );
    return $error;
}

=head1 NAME

TAPER::Controller::Root - Root Controller for TAPER

=head1 DESCRIPTION

This is TAPER's root controller. It's basically Catalyst's default
root controller, pretty much unchanged except for the documentation
you are now reading. More interesting controller activity occurs in
the various TAPER::Controller::* modules.


=head1 METHODS

=head2 index

Show the home page.

=head2 default

The catch-all default action. Returns a 404 status response.

=head2 end

Attempt to render a view, if needed.

=head2 preservation_rules

Show the table of preservation rules.

=head2 validate_nonempty_repeatable
=head2 validate_producers
=head2 validate_extents
=head2 validate_dateSpans

Private helper actions for validating repeatable fields on a submitted
FormFu form.

=head1 AUTHOR

Jason McIntosh, Appleseed Software Consulting <jmac@appleseed-sc.com>
Doug Orleans, Appleseed Software Consulting <dougo@appleseed-sc.com>

=head1 COPYRIGHT

Copyright (c) 2009-2010 by Tufts University.

=cut

1;
