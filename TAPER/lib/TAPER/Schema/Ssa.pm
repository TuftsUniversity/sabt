package TAPER::Schema::Ssa;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ssa");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "path",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 64 },
  "office",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many("rsas", "TAPER::Schema::Rsa", { "foreign.ssa" => "self.id" });
__PACKAGE__->belongs_to("office", "TAPER::Schema::Office", { id => "office" });


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-03-10 23:08:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:22Hh9FZkntYfTWhXZtkFag

use File::Spec;

sub absolute_path {
    my $self = shift;

    return File::Spec->rel2abs( $self->path, TAPER->config->{ssa_directory} );
}

1;

=head1 NAME

TAPER::Schema::Ssa - DBIC Schema for regular submission agreements

=head1 DESCRIPTION

This is a simple DBIC schema module that maps the TAPER 'ssa' table
into Perl objects. It is a subclass of DBIx::Class; see also.

Objects of this class relate only to The database-specific part of
regular submission agreements. See L<TAPER::Logic::SSA> for a more
complete abstarction later to SSAs.

=head1 METHODS

=head2 Accessors

These accessors are called in typical Perl style: they always return
the object's like-named attribute, and if called with an argument,
then they set the attribute to that argument value first. (If the
argument value is inavlid for that attribute, it'll throw an
exception.)

=over

=item id

This SSA's database ID.

=item path

The filesystem path of this SSA's XML file.  If the path is relative,
it is relative to the path specified by the ssa_directory
configuration setting (in taper.conf).

=item absolute_path

I<Read-only.> The absolute filesystem path of this SSA's XML file.

=item office

The office to which this SSA belongs. (See L<TAPER::Schema::Office>.)

=item rsas

I<Read-only.> Returns either a list or a resultset (depending on list
or scalar context) of all the RSAs associated with this SSA.

=back

=head1 AUTHOR

Jason McIntosh <jmac@appleseed-sc.com>
Doug Orleans <dougo@appleseed-sc.com>

=head1 COPYRIGHT

Copyright (c) 2009-2010 by Tufts University.
