package RTDevSys::Cmd::Command::plugins;

#{{{

=pod

=head1 NAME

RTDevSys::Cmd::Command::plugins

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

sub abstract { "Install, load, configure, and create plugins" }

sub usage_desc {
  my ($self) = @_;
  my ($command) = $self->command_names;
  return "%c $command %o [list of plugins...]"
}

has install => (
    isa => "Bool",
    is => "rw",
    documentation => "Only run plugin installations",
);

has load => (
    isa => "Bool",
    is => "rw",
    documentation => "Only load plugin data",
);

has config => (
    isa => "Bool",
    is => "rw",
    documentation => "Only write plugin configuration file",
);

has clean => (
    isa => "Bool",
    is => "rw",
    documentation => "cleanup the plugin installation files.",
);

has deploy => (
    isa => "Bool",
    is => "rw",
    documentation => "Clean, install, load, and configure (default)",
);

sub run {
    my ($self, $opt, $plugins) = @_;
    $plugins = plugin_list() unless @$plugins;

    require RTDevSys::Plugins;

    RTDevSys::Plugins::clean_plugins( $plugins ) if $self->clean;

    my $noop = not ( $self->load || $self->config || $self->install );
    return if ( $self->clean ) and $noop;

    my $all = $self->deploy || $noop;

    RTDevSys::Plugins->import();
    install_plugins( $plugins ) if $all || $self->install;
    load_plugins( $plugins ) if $all || $self->load;
    config_plugins( $plugins ) if $all || $self->config;
    print "\n";
    clean_plugins( $plugins ) if $all;
}

add_deploy_task(
    'plugins',
    sub {
        require RTDevSys::Plugins;
        RTDevSys::Plugins::deploy();
    },
    depends => [ 'system' ]
);

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

