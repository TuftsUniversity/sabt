package TAPER::Schema::User;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("user");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "username",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 16 },
  "first_name",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 64 },
  "last_name",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 64 },
  "is_dca",
  { data_type => "TINYINT", default_value => 0, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "user_offices",
  "TAPER::Schema::UserOffice",
  { "foreign.user" => "self.id" },
);
__PACKAGE__->has_many(
  "user_roles",
  "TAPER::Schema::UserRole",
  { "foreign.user" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-03-10 23:08:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cpk+mjdTFFpshqJ614S0Uw

__PACKAGE__->many_to_many( offices => 'user_offices', 'office' );

sub active_offices {
    my $self = shift;

    return ( map { $_->office }
	     $self->user_offices_sorted->search( { active => 1 } ) );
}

sub user_offices_sorted {
    my $self = shift;

    return $self->user_offices->search( undef, { join => 'office',
						 order_by => 'office.name' } );
}

1;

=head1 NAME

TAPER::Schema::User - DBIC Schema for TAPER users

=head1 SYNOPSIS

# From within a Catalyst controller...
my $user = $c->model( 'TAPERDB::User' )->find( 42 );
my @offices = $user->offices;

=head1 DESCRIPTION

This is a simple DBIC schema module that maps the TAPER 'user' table
into Perl objects. It is a subclass of DBIx::Class; see also.

=head1 METHODS

=head2 Accessors

These accessors are called in typical Perl style: they always return
the object's like-named attribute, and if called with an argument,
then they set the attribute to that argument value first. (If the
argument value is inavlid for that attribute, it'll throw an
exception.)

Don't forget to call update() after making changes...

=over

=item id

This user's database ID.

=item username

This user's username. Not coincidentally, it'll also be a valid
username on Tufts' LDAP system.

=item is_dca

If set to a true value, then this user is treated as a DCA staff
member for purposes of authorization.

=item offices

I<Read-only.> Returns a list or resultset (depending on list / scalar
context) of offices to which this user belongs. (See
L<TAPER::Schema::Office>.)

=item active_offices

I<Read-only.> Returns a list of offices of which this user is an
active member. (See L<TAPER::Schema::Office>.)

=item user_offices

I<Read-only.> Returns a list or resultset (depending on list / scalar
context) of UserOffice objects to which this user belongs. (See
L<TAPER::Schema::UserOffice>.)

=item user_offices_sorted

I<Read-only.> Same as user_offices, but sorted in alphabetical order
of the office names.

=back

=head1 AUTHOR

Jason McIntosh <jmac@appleseed-sc.com>
Doug Orleans <dougo@appleseed-sc.com>

=head1 COPYRIGHT

Copyright (c) 2009-2010 by Tufts University.

