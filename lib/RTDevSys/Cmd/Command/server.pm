package RTDevSys::Cmd::Command::server;

#{{{

=pod

=head1 NAME

RTDevSys::Cmd::Command::server

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

use Moose;
extends qw(MooseX::App::Cmd::Command);

with 'RTDevSys::Cmd::Roles::Standard';

sub abstract { "Control the rt standalone server" }

sub usage_desc {
  my ($self) = @_;
  my ($command) = $self->command_names;
  return "%c $command %o"
}

has 'start' => (
    isa => "Int",
    is => "rw",
    default => 8080,
    documentation => "port server should run on.",
);

sub run {
    my ($self, $opt, $args) = @_;

    exec RTDevSys->RTHOME . "/bin/standalone_httpd " . $self->start;
}

1;

__END__

=head1 AUTHORS

Chad Granum E<lt>chad@opensourcery.comE<gt>

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

