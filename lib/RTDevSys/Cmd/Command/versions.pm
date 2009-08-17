package RTDevSys::Cmd::Command::versions;

#{{{

=pod

=head1 NAME

RTDevSys::Cmd::Command::versions

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
use RTDevSys::Versions;

use Moose;
extends qw(MooseX::App::Cmd::Command);

with 'RTDevSys::Cmd::Roles::Standard';

sub abstract { "Displaye version info" }

sub usage_desc {
  my ($self) = @_;
  my ($command) = $self->command_names;
  return "%c $command %o"
}

has 'plugins' => (
    isa => "Bool",
    is => "rw",
    documentation => "Show plugins",
);

has 'workflows' => (
    isa => 'Bool',
    is => "rw",
    documentation => "Show workflows",
);

has 'system' => (
    isa => "Bool",
    is => "rw",
    documentation => "Show system",
);

sub run {
    my ($self, $opt, $args) = @_;

    my @columns;

    push @columns => show_plugins() if $self->plugins or not ( $self->workflows or $self->system );
    push @columns => show_workflows() if $self->workflows or not ( $self->plugins or $self->system );
    push @columns => show_system() if $self->system or not ( $self->plugins or $self->workflows );

    my $i = 0;
    while( grep { $_->[$i] } @columns ) {
        printf('| %-20s | %-20s | %-20s |' . "\n", map { $_->[$i] || "" } @columns);
        $i++
    }
}

sub show_plugins {
    my @out;
    push @out => "== Plugins ==";
    push @out => " ";

    for my $plugin ( @{plugin_list()} ) {
        push @out => "$plugin:";
        push @out => "  Current: " . _get_( $plugin, 'plugin', 'current' );
        push @out => "     Demo: " . _get_( $plugin, 'plugin', 'demo' );
        push @out => "   Stable: " . _get_( $plugin, 'plugin', 'stable' );
        push @out => " ";
    }
    return \@out;
}

sub show_workflows {
    my @out;
    push @out => "== Workflows ==";
    push @out => " ";

    for my $workflow ( @{workflow_list()} ) {
        push @out => "$workflow:";
        push @out => "  Current: " . _get_( $workflow, 'workflow', 'current' );
        push @out => "     Demo: " . _get_( $workflow, 'workflow', 'demo' );
        push @out => "   Stable: " . _get_( $workflow, 'workflow', 'stable' );
        push @out => " ";
    }
    return \@out;
}

sub show_system {
    my @out;
    push @out => "== System ==";
    push @out => " ";

    push @out => " Current: " . _get_( 'db_version', 'system', 'current' );
    push @out => "    Demo: " . _get_( 'db_version', 'system', 'demo' );
    push @out => "  Stable: " . _get_( 'db_version', 'system', 'stable' );
    push @out => " ";
    return \@out;
}

sub _get_ {
    my ( $item, $type, $build ) = @_;

    return _get_current( $item, $type ) if $build eq 'current'
                                 and $type ne 'plugin';

    $build = 'demo' if $build eq 'current';
    my $data = item_version( $type, $item );
    my $out = $data->{ $build };
    if ( $build eq 'demo' and not $out ) {
        $out = $data->{ stable };
    }
    return defined $out ? $out : 'X';
}

sub _get_current {
    my ( $item, $type ) = @_;
    my $mig_path;
    if ( $type eq 'workflow' ) {
        $mig_path = join( '/', RTDevSys->config->workflows, workflow_path( $item ), "migrations" );
    }
    else {
        $mig_path = RTDevSys->config->system_migrations;
    }
    return '0' unless -d $mig_path;

    my $max = 0;
    opendir( my $DIR, $mig_path ) || die( "Cannot open migration dir: $!\n" );
    for my $file ( readdir( $DIR )) {
        next unless -d "$mig_path/$file";
        next unless $file =~ m/^(\d+)-/;
        my $new = int($1);
        $max = $new if $new > $max;
    }
    closedir( $DIR );
    return $max || '0';
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

