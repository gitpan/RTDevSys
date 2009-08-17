package RTDevSys::Workflows;

#{{{

=pod

=head1 NAME

RTDevSys::Workflows.

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

our @EXPORT = qw/run_migrations initialize_workflow/;

use RTDevSys;
use RTDevSys::Util;
use RTDevSys::DB;
use RTDevSys::Cron;
use RTDevSys::Versions;

sub run_migrations {
    my ( $component, $item, $path ) = @_;

    my $current = get_component_ver( $component, $item ) || 0;
    print "** Upgrading from $item: $current **\n";

    $path ||= RTDevSys->config->workflows . "/" . workflow_path( $item ) . "/migrations";
    unless ( -d $path ) {
        print "No migrations present.\n";
        return;
    }

    opendir( my $migrations, $path ) || die ( "$!\n" );
    for my $dir ( sort readdir( $migrations )) {
        next unless ( -d "$path/$dir" );
        next if $dir =~ m/^\.+$/;

        next unless $dir =~ m/^(\d+)-.*/g;
        my $ver = $1;
        next unless $ver > $current;

        unless( RTDevSys::Versions::_can_install_workflow( $component, $item, $ver )) {
            print "migration: $path/$dir is not stable, skipping\n";
            closedir( $migrations );
            next;
        }

        add_cron( "$path/$dir/cron-add" ) if -e "$path/$dir/cron-add";
        del_cron( "$path/$dir/cron-del" ) if -e "$path/$dir/cron-del";

        if ( -e "$path/$dir/initialdata" ) {
            print "Loading: $path/$dir/initialdata\n";
            load_initialdata( "$path/$dir/initialdata" );
        }
        if ( -e "$path/$dir/update" ) {
            print "Running: $path/$dir/update\n";
            run_command( "WORKING_DIR='$path/$dir' $path/$dir/update" );
        }
        update_component_ver( $component, $item, $ver );
    }
    closedir( $migrations );
}

sub initialize_workflow {
    my ( $item, $path ) = @_;

    unless( can_install_workflow( $item )) {
        print "Not installing workflow: $item\n";
        return;
    }
    $path ||= RTDevSys->config->workflows . "/" . workflow_path( $item );

    my $version = get_component_ver( 'workflow', $item );
    return if ( defined $version );

    print "*** Data for workflow: $item ***\n";

    opendir( my $files, $path ) || die( "Cannot open workflow dir: $!\n" );
    for my $file ( sort readdir( $files )) {
        next unless -f "$path/$file";
        next unless $file =~ m/\.pm$/;
        print( "Loading file: $path/$file...\n" );
        load_initialdata( "$path/$file" );
    }

    print( "...done\n" );
    closedir( $files );
    update_component_ver( 'workflow', $item, 0 );
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

