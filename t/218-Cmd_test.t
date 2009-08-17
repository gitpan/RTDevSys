use strict;
use warnings;

use Test::More tests => 1;
use RTDevSys::Test;

BEGIN{ use_ok('RTDevSys::Cmd::Command::test'); }

__END__

package RTDevSys::Cmd::Command::test;
use strict;
use warnings;
use RTDevSys;
use RTDevSys::Util;

our $RESTORE = 0;

use Moose;
extends qw(MooseX::App::Cmd::Command);

with 'RTDevSys::Cmd::Roles::Standard';

sub abstract { "Test utilities." }

sub usage_desc {
  my ($self) = @_;
  my ($command) = $self->command_names;
  return "%c $command %o [build]"
}

has 'reset_email' => (
    isa => "Str",
    is => "rw",
    documentation => "change all email addresses to use specified domain.",
);

has 'reset_pass' => (
    isa => "Str",
    is => "rw",
    documentation => "reset all user passwords to the specified.",
);

has 'shred' => (
    isa => "Bool",
    is => "rw",
    documentation => "Shred the current database",
);

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


sub run {
    my ($self, $opt, $args) = @_;
    return shred_db() if $self->shred;

    return $self->_reset() if ( $self->reset_email || $self->reset_pass );

    backup_db();
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
        backup_db();
        $self->run_tests( "plugins/$plugin/t/*.t" );
        restore_db();
    }
}

sub test_wrapper {
    my $self = shift;
    my $sub = shift;

    backup_db();

    RTDevSys::Plugins::deploy() unless $self->no_plugins;

    unless ( $self->no_workflows ) {
        for my $item ( @{ workflow_list() }) {
            initialize_workflow( $item );
            run_migrations( 'workflow', $item )
        }
    }

    $sub->( $self, @_ );
}

sub backup_db {
    return if $RESTORE;
    print "Dumping database before test...\n";
    RTDevSys::DB::dumpdb( '.test.psqlc' );
    $RESTORE++;
}

sub restore_db {
    return unless $RESTORE;
    print "Restoring database...\n";
    RTDevSys::DB::dropdb();
    RTDevSys::DB::createdb();
    RTDevSys::DB::loaddb( '.test.psqlc' );
    $RESTORE = 0;
}

sub run_tests {
    my $self = shift;
    $self->test_wrapper( \&_run_tests, @_ );
}

sub _run_tests {
    my $self = shift;
    my @tests = @_;

    my $command = 'prove ';
    $command .= "-v " if $self->verbose;
    $command .= join( " ", @tests );
    run_command( "$command || true" );
}

END {
    if ( $RESTORE ) {
        require RTDevSys::DB;
        restore_db();
    }
}

1;
