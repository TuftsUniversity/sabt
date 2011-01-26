package TAPER::Schema::PreservationRule;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("preservation_rule");
__PACKAGE__->add_columns(
    "number",
    { data_type => "INT", default_value => undef, is_nullable => 0, size => 4 },
    "description",
    { data_type => "VARCHAR", default_value => undef, is_nullable => 0, size => 256 },
    "action",
    { data_type => "TEXT", default_value => undef, is_nullable => 0 },
    "related_p_and_p",
    { data_type => "VARCHAR", default_value => undef, is_nullable => 1, size => 256 },
    );

__PACKAGE__->set_primary_key("number");

1;

=head1 NAME

TAPER::Schema::PreservationRule - DBIC Schema for TAPER preservation rules

=head1 SYNOPSIS

# From within a Catalyst controller...
my $rule = $c->model( 'TAPERDB::PreservationRule' )->find( 2 );

=head1 DESCRIPTION

This is a simple DBIC schema module that maps the TAPER
'preservation_rule' table into Perl objects. It is a subclass of
DBIx::Class; see also.

=head1 METHODS

=head2 Accessors

These accessors are called in typical Perl style: they always return
the object's like-named attribute, and if called with an argument,
then they set the attribute to that argument value first. (If the
argument value is inavlid for that attribute, it'll throw an
exception.)

Don't forget to call update() after making changes...

=over

=item number

This preservation rule's rule number.

=item description

This preservation rule's description, including file format extensions.

=item action

A statement of this preservation rule's preservation action.

=item related_p_and_p

I<Optional.> P & P related to this preservation rule, if any.

=back

=head1 AUTHOR

Doug Orleans <dougo@appleseed-sc.com>

=head1 COPYRIGHT

Copyright (c) 2011 by Tufts University.
