package RTDevSys::Cmd::Command::deploy;

#{{{

=pod

=head1 NAME

RTDevSys::Cmd::Command::deploy

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

sub abstract { "Deploy an RT installation" }

sub usage_desc {
  my ($self) = @_;
  my ($command) = $self->command_names;
  return "%c $command %o [build]"
}

has 'loaddb' => (
    isa => "Str",
    is => "rw",
    documentation => "Load database from specified file.",
);

has 'initdb' => (
    isa => "Bool",
    is => "rw",
    documentation => "Initialize a new RT database",
);

sub run {
    my ($self, $opt, $args) = @_;
    my $tasks = RTDevSys->deploy_tasks;

    for my $task (@{ tasksort( $tasks )}) {
        print "\nTask: $task\n";
        $tasks->{ $task }->{ _sub }->( $self );
    }
}

sub tasksort {
    my $tasks = shift;
    my $out = [
        sort {
            # a is lower than b if b depends on a.
            my $adeps = $tasks->{ $a }->{ depends } || [];
            my $bdeps = $tasks->{ $b }->{ depends } || [];
            $adeps = [ $adeps ] unless ref $adeps eq 'ARRAY';
            $bdeps = [ $bdeps ] unless ref $bdeps eq 'ARRAY';

            return -1 if grep { $a eq $_ } @$bdeps;
            # a is higher than b is a depends on b.
            return 1 if grep { $b eq $_ } @$adeps;
            return 0;
        } keys %$tasks
    ];
    return $out;
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

