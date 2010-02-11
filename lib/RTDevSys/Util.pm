package RTDevSys::Util;

#{{{ POD

=head1 NAME

RTDevSys::Util - Utility functions for RTDevSys

=head1 EARLY VERSION WARNING

This is a very early version of RTDevSys. It is ready for use, and in fact is
being used. However there may be some API changes in the future. As well there
may be some missing, incomplete, or untested features. At the moment the
database commands only support postgres not mysql.

=head1 DESCRIPTION

This module provides several utility functions used all over RTDevSys.

=head1 SYNOPSIS

    use RTDevSys qw(workflow_path workflow_list plugin_list include_list
                    run_command load_initialdata strip_lead add_inc);

=head1 EXPORTED FUNCTIONS

=over 4

=cut

#}}}

use strict;
use warnings;
use RTDevSys;

use base 'Exporter';

our @EXPORT = qw/workflow_path workflow_list plugin_list include_list
run_command load_initialdata strip_lead add_inc/;

=item workflow_list()

Returns an arrayref containing the names of all the workflows within the
workflow directory. If the optional first parameter is true then prefixed
numbwers will be listed as well.

    print "$_\n" for @{ workflow_list() };
    # WorkflowA
    # WorkflowB
    # workflowC

    print "$_\n" for @{ workflow_list( 1 ) };
    # 001-WorkflowA
    # 002-WorkflowB
    # 003-WorkflowC

Note: Workflows are any directory not prefixed by a '.' within the workflows
directory. Workflow directories may be prefixed by a number ( ###-Name ), but
do not need to be. The number is used for sorting only. When refering to a
workflow in code you generally do not use its prefix.

=cut

sub workflow_list {
    my ( $with_lead ) = @_;
    my $list = [];
    my $wf_dir = RTDevSys->config->workflows;
    opendir( my $workflows, $wf_dir ) || die ( "Cannot open workflow directory '$wf_dir': $!\n" );
    for my $item ( sort readdir( $workflows )) {
        next if $item =~ m/^\.+/;
        next unless -d RTDevSys->config->workflows . "/$item";
        push @$list => $with_lead ? $item : strip_lead( $item );
    }
    closedir( $workflows );
    return $list;
}

=item workflow_path()

Takes one argument, name of the workflow in question. Returns the name of the
folder the workflow is contained in. Note this does not include the full path,
just the workflow directory.

=cut

sub workflow_path {
    my ( $item ) = @_;

    my $item_path = $item;
    unless( -d RTDevSys->config->workflows . "/$item_path" ) {
        ($item_path) = grep { m/^(\d+-)?$item$/ } @{ workflow_list( 1 )};
        die( "Could not find path for workflow: $item\n" ) unless $item_path;
    }
    return $item_path;
}

=item plugin_list()

Returns an arrayref of plugin names. Similar to workflow_list()

=cut

sub plugin_list {
    my $list = [];
    opendir( my $plugins, RTDevSys->config->plugins ) || die ( "Cannot open plugins directory: $!\n" );
    for my $item ( sort readdir( $plugins )) {
        next if $item =~ m/^\.+/;
        next unless -d RTDevSys->config->plugins . "/$item";
        push @$list => $item;
    }
    closedir( $plugins );
    return $list;
}

=item include_list()

Returns a list of include directories that should be added to @INC. These are
usually the RT installation folder library paths. It also includes the ./lib
dir, and ~/RTDevSys/lib/perl5 (for locallib users).

=cut

sub include_list {
    return [
        $ENV{HOME} . "/RTDevSys/lib/perl5",
        RTDevSys->RTHOME . "/etc",
        RTDevSys->RTHOME . "/lib",
        RTDevSys->RTHOME . "/local/lib",
        "lib",
        glob( RTDevSys->RTHOME . "/local/plugins/*/lib"),
        $ENV{ PERL5LIB } || "",
    ]
}

=item run_command()

Runs the specified command through system(). Before running the command however
it sets a local %ENV to match RTDevSys's environment variables. Will die if the
command does not exit cleanly.

=cut

sub run_command {
    my $command = shift;
    local %ENV = %{ RTDevSys::local_env() };
    system( $command ) and die( "Command did not exit cleanly.\n** $command\n" );
}

=item load_initialdata

Takes an initialdata filename as an argument. Will load the initialdata file
using rt-setup-database.

=cut

sub load_initialdata {
    my $file = shift;
    run_command( _initial_data_command( $file ));
}

sub _initial_data_command {
    my ( $file ) = shift;
    return RTDevSys->RTHOME
           . "/sbin/rt-setup-database --action insert --datafile '$file' --dba-password '"
           . RTDevSys->RT_DB_PASSWORD
           . "'";
}

=item strip_lead()

Strips the ###- from the beginning of a workflow name.

    my $name = strip_lead( '001-Name' );
    print $name;
    # prints: Name

=cut

sub strip_lead {
    my $item = shift;
    $item =~ s/^\d+-//;
    return $item;
}

=item add_inc()

Will add all the paths from include_list() to @INC.

This will take action once.

=cut

{
    my $added;
    sub add_inc {
        return if $added;
        my $path = RTDevSys->RTHOME;
        unshift @INC => @{ include_list() };
    }
}

1;

__END__

=back

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
