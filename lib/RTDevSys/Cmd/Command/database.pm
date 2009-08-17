package RTDevSys::Cmd::Command::database;

#{{{

=pod

=head1 NAME

RTDevSys::Cmd::Command::database

=head1 EARLY VERSION WARNING

This is a very early version of RTDevSys. It is ready for use, and in fact is
being used. However there may be some API changes in the future. As well there
may be some missing, incomplete, or untested features. At the moment the
database commands only support postgres not mysql.

=cut

#}}}

use strict;
use warnings;
use RTDevSys;
use RTDevSys::Util;

use Moose;
extends qw(MooseX::App::Cmd::Command);

with 'RTDevSys::Cmd::Roles::Standard';

sub abstract { "Manage the database" }

sub usage_desc {
  my ($self) = @_;
  my ($command) = $self->command_names;
  return "%c $command %o"
}

has 'dump' => (
    isa => "Str",
    is => "rw",
    documentation => "Dump the database to specified file.",
);

has 'mergeable_dump' => (
    isa => "Str",
    is => "rw",
    documentation => "Dump the database to specified file suitable for merging",
);

has 'load' => (
    isa => "Str",
    is => "rw",
    documentation => "Load database from specified file.",
);

has 'drop' => (
    isa => "Bool",
    is => "rw",
    documentation => "Drop the database.",
);

has 'create' => (
    isa => "Bool",
    is => "rw",
    documentation => "Create the database.",
);

has 'merge' => (
    isa => "Str",
    is => "rw",
    documentation => "Merge in a database backup dump",
);

sub run {
    my ($self, $opt, $args) = @_;

    require RTDevSys::DB;

    RTDevSys::DB::dumpdb( $self->dump ) if $self->dump;
    RTDevSys::DB::loaddb( $self->load ) if $self->load;
    RTDevSys::DB::dropdb() if $self->drop;
    RTDevSys::DB::createdb() if $self->create;
    RTDevSys::DB::dumpdb( $self->mergeable_dump, flags => '-d -a' ) if $self->mergeable_dump;
    RTDevSys::DB::mergedb( $self->merge ) if $self->merge;
}

add_deploy_task(
    'database',
    sub {
        my $deploy_cmd = shift;
        require RTDevSys::DB;
        if ( $deploy_cmd->loaddb ) {
            my $db = $deploy_cmd->loaddb;
            RTDevSys::DB::dropdb();
            RTDevSys::DB::createdb();
            RTDevSys::DB::loaddb( $db );
        }
    },
    depends => [ 'rt' ],
);


1;

__END__

=head1 AUTHORS

Chad Granum E<lt>chad@opensourcery.comE<gt>

Ryan Whitehurst E<lt>ryan@opensourcery.comE<gt>

=head1 COPYRIGHT

Copyright 2009 OpenSourcery, LLC.

This file is part of RTDevSys

RTDevSys is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

RTDevSys is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with RTDevSys.  If not, see <http://www.gnu.org/licenses/>.

=cut

