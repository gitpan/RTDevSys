package RTDevSys::Cmd::Command::rt;

#{{{

=pod

=head1 NAME

RTDevSys::Cmd::Command::rt - Command to manage installations of RT.

=head1 EARLY VERSION WARNING

This is a very early version of RTDevSys. It is ready for use, and in fact is
being used. However there may be some API changes in the future. As well there
may be some missing, incomplete, or untested features. At the moment the
database commands only support postgres not mysql.

=head1 DESCRIPTION

This class is a command used to install, uninstall, and patch RT.

=head SYNOPSIS

    $ rtdevsys rt --install
    $ rtdevsys rt --uninstall
    $ rtdevsys help rt

=head1 ATTRIBUTES

Attributes are flags that can be passed to the command line.

    $ rtdevsys rt --ATTRIBUTE

=over 4

=cut

#}}}

use strict;
use warnings;
use RTDevSys;
use RTDevSys::Util;
use File::Path qw/mkpath/;

use Moose;
extends qw(MooseX::App::Cmd::Command);

with 'RTDevSys::Cmd::Roles::Standard';

sub abstract { "RT Installation" }

sub usage_desc {
  my ($self) = @_;
  my ($command) = $self->command_names;
  return "%c $command %o"
}

=item install

Install RT (implies --patch)

=cut

has 'install' => (
    isa => "Bool",
    is => "rw",
    documentation => "Install RT (implies --patch)",
);

=item uninstall

Uninstall RT (implies --clean)

=cut

has 'uninstall' => (
    isa => "Bool",
    is => "rw",
    documentation => "Uninstall RT (implies --clean)",
);

=item patch

Apply patches

=cut

has 'patch' => (
    isa => "Bool",
    is => "rw",
    documentation => "Apply patches",
);

=item unpatch

Unapply patches

=cut

has 'unpatch' => (
    isa => "Bool",
    is => "rw",
    documentation => "Unapply patches",
);

=item test

Run the RT test suite

=cut

has 'test' => (
    isa => "Bool",
    is => "rw",
    documentation => "Run the RT test suite",
);

=item clean

Clean RT installation (implies --unpatch)

=cut

has 'clean' => (
    isa => "Bool",
    is => "rw",
    documentation => "Clean RT installation (implies --unpatch)",
);

=item initdb

initialize the database

=cut

has 'initdb' => (
    isa => "Bool",
    is => "rw",
    documentation => "initialize the database",
);

sub run {
    my ($self, $opt, $args) = @_;

    uninstall_rt() if $self->uninstall;
    patch_rt() if $self->patch;
    install_rt() if $self->install;
    test_rt() if $self->test;
    unpatch_rt() if $self->unpatch;
    rt_initdb() if $self->initdb;
}

=back

=head1 DEPLOYMENT TASKS

This command adds the following deployment tasks. Deployment tasks are run when
the 'deploy' command is used.

=over 4

=cut

=item rt

This does the following:

    uninstall rt
    make sure old patches are undone.
    patch rt installation files
    install rt
    unpatch rt installation files
    init the database (if requested)

=cut

add_deploy_task(
    'rt',
    sub {
        my $deploy_cmd = shift;
        uninstall_rt();
        patch_rt();
        install_rt();
        unpatch_rt();
        rt_initdb() if $deploy_cmd->initdb;
    }
);

=item config

This deployment task will move the RT_SiteConfig file RT installs by default to
your custom config directory, unless a config file already exists there. It
will then put a new RT_SiteConfig file in place that redirects to the custom
one.

=cut

add_deploy_task(
    'config',
    sub {
        my $path = RTDevSys->RT_CONF_PATH;
        mkpath( $path );
        die( "Unable to create path: $path: $!\n" ) unless -d $path;
        # move installed RT_SiteConfig
        system("mv '" . RTDevSys->RTHOME . "/etc/RT_SiteConfig.pm' '$path/'") unless -e "$path/RT_SiteConfig.pm";
        # install RT_SiteConfig
        open( my $config, ">", RTDevSys->RTHOME . "/etc/RT_SiteConfig.pm" ) || die ("Cannot write RT_SiteConfig.pm: $!\n");
        print $config site_config();
        close( $config );
    },
    depends => 'database',
);

=back

=head1 FUNCTIONS

=over 4

=cut

=item site_config()

This function writes a RT_SiteConfig.pm file to the installation directory. The
generated file will simply require the custom config file, and the plugins
config file.

=cut

sub site_config {
    my $file = RTDevSys->RT_CONF_PATH . "/RT_SiteConfig.pm";
    return <<EOT;
require '$file';
require 'RT_SitePlugins.pm';
1;
EOT
}

=item install_rt

This function will install RT to the RT installation directory as specified in
the RTDSConfig file, or command line arguments.

=cut

sub install_rt {
    my $vendor_rt = RTDevSys->config->rt;
    my $command = <<EOT;
  cd "$vendor_rt";
  ./configure \\
EOT
    my %params = (
        'prefix' => 'RTHOME',
        'with-bin-owner'  => 'RT_USER',
        'with-libs-owner' => 'RT_USER',
        'with-libs-group' => 'RT_GROUP',
        'with-db-type'    => 'RT_DB_DRIVER',
        'with-db-dba'     => 'RT_DB_USER',
        'with-db-database' => 'RT_DB',
        'with-db-rt-user' => 'RT_USER',
        'with-db-rt-pass' => 'RT_DB_PASSWORD',
        'with-db-host'    => 'RT_DB_HOST',
        'with-db-port'    => 'RT_DB_PORT',
        'with-rt-group'   => 'RT_GROUP',
        'with-web-user'   => 'WEB_USER',
        'with-web-group'  => 'WEB_GROUP',
    );

    while ( my ( $param, $var ) = each %params ) {
        $command .= "--$param='" . RTDevSys->$var . "' \\\n";
    }

    $command .= "\nmake install;";
    print $command;
    run_command( $command );
}

=item uninstall_rt()

Uninstall RT (rm -rf INSTALL_DIR)

=cut

sub uninstall_rt {
    run_command( 'rm -rf ${RTHOME}' );
}

=item rt_initdb()

Run the initialize-database make rule from the RT source dir. WARNING: WILL
DROP THE DATABASE FIRST

=cut

sub rt_initdb {
    my $vendor_rt = RTDevSys->config->rt;
    my $command = <<EOT;
  cd "$vendor_rt";
  make dropdb initialize-database
EOT
    run_command( $command );
}

sub _patch_rt {
    my ( $reverse, $quiet ) = @_;
    my $patchpath = RTDevSys->config->patches;
    my $vendor_rt = RTDevSys->config->rt;
    opendir( my $patchdir, $patchpath ) || die( "Unable to open patch dir: $!" );
    my @patches = grep { -f "$patchpath/$_" && m/^\d+-(.*)\.patch$/ } readdir( $patchdir );
    closedir( $patchdir );

    my $flags = $reverse ? '-Rf' : '-Nf';
    @patches = sort( @patches );
    @patches = reverse( @patches ) if $reverse;

    for my $patch ( @patches ) {
        print $reverse ? "Unapplying" : "Applying" unless $quiet;
        print " patch: $patch..." unless $quiet;
        system( "patch -d $vendor_rt -p0 $flags -i '" . RTDevSys->rootdir . "/$patchpath/$patch' > /dev/null 2>&1" );
        print $? ? "Failed\n" : "Success\n" unless $quiet;
    }
}

=item patch_rt()

Silently unpatches the RT installation source, then proceeds to patch it again.

=cut

sub patch_rt {
    _patch_rt( 1, 1 );
    _patch_rt();
}

=item unpatch_rt

Unpatch the RT installation source.

=cut

sub unpatch_rt {
    _patch_rt( 1 );
}

sub test_rt {
    run_command('perl -MExtUtils::Command::MM -e "test_harness(0, \'${RTHOME}/lib\', \'${RTHOME}/local/lib\')" vendor/rt/t/*.t vendor/rt/t/*/*.t');
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

