package RTDevSys::Cmd::Command::init;

#{{{

=pod

=head1 NAME

RTDevSys::Cmd::Command::init - Command for initializing an RT project folder.

=head1 EARLY VERSION WARNING

This is a very early version of RTDevSys. It is ready for use, and in fact is
being used. However there may be some API changes in the future. As well there
may be some missing, incomplete, or untested features. At the moment the
database commands only support postgres not mysql.

=cut

#}}}

use strict;
use warnings;
use File::Path qw/mkpath/;

use Moose;
extends qw(MooseX::App::Cmd::Command);

has 'rt' => (
    isa => "Str",
    is => "rw",
    documentation => "path for rt",
    default => "vendor/rt",
);

has 'patches' => (
    isa => "Str",
    is => "rw",
    documentation => "path for patches",
    default => "vendor/patches",
);

has 'workflows' => (
    isa => "Str",
    is => "rw",
    documentation => "path for workflows",
    default => "workflows",
);

has 'plugins' => (
    isa => "Str",
    is => "rw",
    documentation => "path for plugins",
    default => "plugins",
);

has 'versions_table' => (
    isa => "Str",
    is => "rw",
    documentation => "table name for holding DevSys version tracking",
    default => "devsys_versions",
);

has 'system_migrations' => (
    isa => "Str",
    is => "rw",
    documentation => "path for system_migrations",
    default => "migrations",
);

has 'database_driver' => (
    isa => "Str",
    is => 'rw',
    documentation => 'database driver to use (Pg or mysql)',
    default => 'Pg',
);

sub abstract { "Initialize a project directory" }

sub usage_desc {
  my ($self) = @_;
  my ($command) = $self->command_names;
  return "%c $command %o [DIR]";
}

sub run {
    my ($self, $opt, $args) = @_;
    my ( $path ) = @$args;
    $path ||= ".";

    mkpath( "$path/" . $self->$_ ) for qw/rt patches workflows plugins system_migrations/;

    open( my $config, ">", "$path/RTDS_Config.pm" ) || die("Unable to write RTDS_Config: $!\n");
    print $config $self->RTDS_Config();
    close( $config );

    open( my $versions, ">", "$path/versions.yaml" ) || die("Unable to write versions.yaml: $!\n");
    print $versions versions();
    close( $versions );
}

sub RTDS_Config {
    my $self = shift;
    my $rt         = $self->rt;
    my $patches    = $self->patches;
    my $workflows  = $self->workflows;
    my $plugins    = $self->plugins;
    my $versions_table    = $self->versions_table;
    my $system_migrations = $self->system_migrations;
    my $driver = $self->database_driver;

    return <<EOT;
use strict;
use warnings;
use RTDevSys::Config;
use RTDevSys::Config::Build;

my \$config = RTDevSys::Config->new(
    rt          => "$rt",
    patches     => "$patches",
    workflows   => "$workflows",
    plugins     => "$plugins",
    versions_table => "$versions_table",
    system_migrations => "$system_migrations",
);

\$config->add_build(
    devel => RTDevSys::Config::Build->new(
        RTHOME       => \$ENV{ HOME } . "/dev/rt3",
        RT_DB        => "rt_devel",
        RT_DB_HOST   => "127.0.0.1",
        RT_DB_PORT   => 5432,
        RT_DB_USER   => \$ENV{ USER },
        RT_DB_DRIVER    => "$driver",
        RT_DB_PASSWORD  => sub { chomp( my \$p = `cat db_pass` ); \$p },
        RT_USER      => \$ENV{ USER },
        RT_GROUP     => "users",
        RT_WEB_USER  => \$ENV{ USER },
        RT_WEB_GROUP => "users",
        WEB_USER     => \$ENV{ USER },
        WEB_GROUP    => "users",
        VERSIONS_FILE   => 'versions.yaml',
        RT_CONF_PATH => \$ENV{ HOME } . "/dev/rt3conf",
    )
);

\$config->add_build(
    demo => RTDevSys::Config::Build->new(
        RTHOME       => \$ENV{ HOME } . "/opt/rt3",
        RT_DB        => "rt_devel",
        RT_DB_HOST   => "127.0.0.1",
        RT_DB_PORT   => 5432,
        RT_DB_USER   => \$ENV{ USER },
        RT_DB_DRIVER    => "$driver",
        RT_DB_PASSWORD  => sub { chomp( my \$p = `cat db_pass` ); \$p },
        RT_USER      => \$ENV{ USER },
        RT_GROUP     => "users",
        RT_WEB_USER  => \$ENV{ USER },
        RT_WEB_GROUP => "users",
        WEB_USER     => \$ENV{ USER },
        WEB_GROUP    => "users",
        VERSIONS_FILE   => 'versions.yaml',
        RT_CONF_PATH => "/etc/rt",
    )
);

\$config->add_build(
    stable => RTDevSys::Config::Build->new(
        RTHOME       => \$ENV{ HOME } . "/opt/rt3",
        RT_DB        => "rt_devel",
        RT_DB_HOST   => "127.0.0.1",
        RT_DB_PORT   => 5432,
        RT_DB_USER   => \$ENV{ USER },
        RT_DB_DRIVER    => "$driver",
        RT_DB_PASSWORD  => sub { chomp( my \$p = `cat db_pass` ); \$p },
        RT_USER      => \$ENV{ USER },
        RT_GROUP     => "users",
        RT_WEB_USER  => \$ENV{ USER },
        RT_WEB_GROUP => "users",
        WEB_USER     => \$ENV{ USER },
        WEB_GROUP    => "users",
        VERSIONS_FILE   => 'versions.yaml',
        RT_CONF_PATH => "/etc/rt",
    )
);

return \$config;
EOT
}

sub versions {
    return <<'EOT';
---
# If a plugin or workflow is not listed it will be skipped
# If disable: is true the workflow or plugin will be skipped
# If stable: is missing then the plugin or workflow will not be installed in stable
# If demo: is missing then it will default to stable
# If both are missing it counts as disabled, use devel: 1 to enable it for
# development
# If nothing is listed it is the same as disable
#The system version
system:
  db_version:
    stable: 0
    demo: 0

#plugin versions
plugin:

#workflow versions
workflow:

EOT
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

