package TAPER::Schema::UserOffice;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("user_office");
__PACKAGE__->add_columns(
  "user",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "office",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "active",
  { data_type => "TINYINT", default_value => 1, is_nullable => 0, size => 1 },
);
__PACKAGE__->set_primary_key("user", "office");
__PACKAGE__->belongs_to("user", "TAPER::Schema::User", { id => "user" });
__PACKAGE__->belongs_to("office", "TAPER::Schema::Office", { id => "office" });


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-03-10 23:08:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wHUTY4cd3YkoA5a4iAXjbQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;

=head1 NAME

TAPER::Schema::UserOffice - DBIC Schema for TAPER user-office relationships

=head1 DESCRIPTION

This is a simple DBIC schema module that maps the TAPER 'user_office' table
into Perl objects. It is a subclass of DBIx::Class; see also.

=head1 METHODS

=head2 Accessors

These accessors are called in typical Perl style: they always return
the object's like-named attribute, and if called with an argument,
then they set the attribute to that argument value first. (If the
argument value is inavlid for that attribute, it'll throw an
exception.)

=over

=item user

The associated user (see L<TAPER::Schema::User>.)

=item office

The associated office (see L<TAPER::Schema::Office>.)

=item active

True iff this user-office affiliation is active; otherwise, the user
may not create RSAs using SSAs belonging to this office (unless the
user is DCA).

=back

=head1 AUTHOR

Jason McIntosh <jmac@appleseed-sc.com>
Doug Orleans <dougo@appleseed-sc.com>

=head1 COPYRIGHT

Copyright (c) 2009-2010 by Tufts University.

