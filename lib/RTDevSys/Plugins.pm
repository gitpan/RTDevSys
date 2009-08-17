package RTDevSys::Plugins;

#{{{

=pod

=head1 NAME

RTDevSys::Plugins

=head1 EARLY VERSION WARNING

This is a very early version of RTDevSys. It is ready for use, and in fact is
being used. However there may be some API changes in the future. As well there
may be some missing, incomplete, or untested features. At the moment the
database commands only support postgres not mysql.

=cut

#}}}

use strict;
use warnings;

use base 'Exporter';

our @EXPORT = qw/create_plugin install_plugins load_plugins config_plugins
clean_plugins clean_plugin install_plugin load_plugin/;

use RTDevSys;
use RTDevSys::DB;
use RTDevSys::Util;
use RTDevSys::Versions;

sub deploy {
    my $plugins = plugin_list();
    install_plugins( $plugins );
    load_plugins( $plugins );
    config_plugins( $plugins );
    print "\n";
    clean_plugins( $plugins );
}

sub plugin_command {
    my ( $plugin, $command ) = @_;

    my $path = RTDevSys->config->plugins . "/$plugin";

    my $full = <<EOT;
cd "$path";
$command
EOT
    run_command( $full );
}

sub clean_plugins {
    my ( $plugins ) = @_;
    for my $plugin ( @$plugins ) {
        clean_plugin( $plugin );
    }
}

sub clean_plugin {
    my ( $plugin ) = @_;
    print "Cleaning plugin: $plugin\n";
    my $command = "make clean > /dev/null || true;";
    plugin_command( $plugin, $command );
    return 1;
}

sub install_plugins {
    my ( $plugins ) = @_;
    for my $plugin ( @$plugins ) {
        install_plugin( $plugin );
    }
}

sub install_plugin {
    my ( $plugin ) = @_;
    unless( can_install_plugin( $plugin )) {
        print "Not installing development plugin: $plugin\n";
        return;
    }

    print "\n\nInstalling plugin: $plugin\n";

    my $command = <<EOT;
make clean > /dev/null || true;
perl Makefile.PL || exit 1;
make install || exit 1;
EOT
    plugin_command( $plugin, $command );
    return 1;
}

sub load_plugins {
    my ( $plugins ) = @_;
    print "\n";
    for my $plugin ( @$plugins ) {
        print "Loading data for plugin: $plugin\n";
        load_plugin( $plugin );
    }
}

sub load_plugin {
    my ( $plugin ) = @_;

    my $path = RTDevSys->config->plugins . "/$plugin";

    unless( can_install_plugin( $plugin )) {
        print "Not installing data for plugin: $plugin\n";
        return
    }
    unless( -e "$path/etc/initialdata" ) {
        print "No Data for plugin: $plugin\n";
        return;
    }
    my $version = get_component_ver( 'plugin', $plugin );
    return if ( defined $version );

    print "Initializing...\n";
    load_initialdata( "$path/etc/initialdata" );

    # The version is now just true of false, true for installed.
    # Any module that gets this far should have true.
    unless ( $version ) {
        update_component_ver( 'plugin', $plugin, 1 );
        $version = 1;
    }
    return 1;
}

sub config_plugins {
    my ( $plugins ) = @_;

    my @install = grep { can_install_plugin( $_ ) } @$plugins;
    print "\nWriting config file for the following plugins: " . join( ' ', @install ) . "\n";

    my $destination = RTDevSys->RTHOME . "/etc/RT_SitePlugins.pm";
    open( my $config, ">", $destination ) || die( "Error opening config file: $!\n" );
    print $config 'Set(@Plugins, qw('
        . join( ' ', map { s/-/::/g; "RTx::$_" } @install )
        . "));\n\n1;";
    close( $config );

    return \@install;
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

