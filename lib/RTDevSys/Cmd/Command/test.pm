package RTDevSys::Cmd::Command::test;

#{{{

=pod

=head1 NAME

RTDevSys::Cmd::Command::test

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
use RTDevSys::DB;

our $RESTORE = 0;
our %RAN;

use Moose;
extends qw(MooseX::App::Cmd::Command);

with 'RTDevSys::Cmd::Roles::Standard';

sub abstract { "Test utilities." }

sub usage_desc {
  my ($self) = @_;
  my ($command) = $self->command_names;
  return "%c $command %o [build]"
}

has 'workflows' => (
    isa => "Bool",
    is => "rw",
    documentation => "Load database from specified file.",
);

has 'plugins' => (
    isa => "Bool",
    is => "rw",
    documentation => "Load database from specified file.",
);

has 'verbose' => (
    isa => "Bool",
    is => "rw",
    documentation => "Load database from specified file.",
);

has 'no_data' => (
    isa => "Bool",
    is => 'rw',
    documentation => "Do not reload workflow data",
);

has 'no_plugins' => (
    isa => "Bool",
    is => 'rw',
    documentation => "Do not reload plugins",
);

has 'no_workflows' => (
    isa => "Bool",
    is => 'rw',
    documentation => "Do not reload workflows",
);

has 'debug' => (
    isa => "Bool",
    is => 'rw',
    documentation => "Debug instead of prove",
);

has 'test_backup_db' => (
    isa => "Str",
    is => 'rw',
    lazy => 1,
    default => sub { RTDevSys->RT_DB_DRIVER eq 'Pg' ? '.test.psqlc' : '.test.sql' },
);

has 'test_backup_db_flags' => (
    isa => "Str",
    is => 'rw',
    lazy => 1,
    default => sub { RTDevSys->RT_DB_DRIVER eq 'Pg' ? '-c' : '' },
);

sub run {
    my ($self, $opt, $args) = @_;

    unlink( $self->test_backup_db ) if -e $self->test_backup_db;

    $self->backup_db();
    unless ( $self->no_data ) {
        # Re-Write this for RTx-NNID
        # Only if we get this far
        #require RTDevSys::ScripUpdate;
        #RTDevSys::ScripUpdate->import();
        #capture_scrips();
        #handle_scrips( "workflows" );
    }

    $self->test_workflows if $self->workflows;
    $self->test_plugins if $self->plugins;

    $self->run_tests( @$args ) if @$args;
}


sub test_workflows {
    my $self = shift;
    $self->run_tests( 'workflows/*/t/*.t' );
}

sub test_plugins {
    my $self = shift;
    for my $plugin ( @{ plugin_list() }) {
        $self->backup_db();
        $self->run_tests( "plugins/$plugin/t/*.t" );
        $self->restore_db();
    }
}

sub test_wrapper {
    my $self = shift;
    my $sub = shift;

    $self->backup_db();

    unless ( $RAN{ plugins } or $self->no_plugins ) {
        require RTDevSys::Plugins;
        RTDevSys::Plugins::deploy();
        $RAN{ plugins }++;
    }

    unless ( $RAN{ workflows } or $self->no_workflows ) {
        require RTDevSys::Workflows;
        RTDevSys::Workflows->import();
        for my $item ( @{ workflow_list() }) {
            initialize_workflow( $item );
            run_migrations( 'workflow', $item );
        }
        $RAN{ workflows }++;
    }

    $sub->( $self, @_ );
}

sub backup_db {
    my $self = shift;
    if ( -e $self->test_backup_db ) {
        $RESTORE++;
        return
    }
    return if $RESTORE;
    print "Dumping database before test...\n";
    RTDevSys::DB::dumpdb( $self->test_backup_db, flags => $self->test_backup_db_flags );
    $RESTORE++;
}

sub restore_db {
    my $self = shift;
    return unless $RESTORE;
    print "Restoring database...\n";
    RTDevSys::DB::loaddb( $self->test_backup_db, flags => $self->test_backup_db_flags );
    $RESTORE = 0;
}

sub run_tests {
    my $self = shift;
    $self->test_wrapper( \&_run_tests, @_ );
}

sub _run_tests {
    my $self = shift;
    my @tests = @_;

    my $command = $self->debug ? 'perl -d ' : 'prove ';
    $command .= "-v " if $self->verbose and not $self->debug;
    $command .= join( " ", @tests );
    run_command( "$command || true" );
}

sub DESTROY {
    my $self = shift;
    if ( $RESTORE and -e $self->test_backup_db ) {
        require RTDevSys::DB;
        $self->restore_db();
        unlink( $self->test_backup_db ) if -e $self->test_backup_db;
    }
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

