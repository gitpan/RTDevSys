use strict;
use warnings;

use Test::More tests => 7;
use RTDevSys::Test;
use RTDevSys::Cmd;
use RTDevSys::DB;

BEGIN{ use_ok('RTDevSys::Cmd::Command::database'); }

my %ACTIONS;
for my $sub ( qw/dumpdb loaddb dropdb createdb/ ) {
    override( 'RTDevSys::DB', $sub, sub { $ACTIONS{ $sub }++ } );
}

{
    package Fake;
    use Moose;
    has loaddb => (
        isa => 'Bool',
        is => 'rw',
    );
}

ok( my $task = RTDevSys->deploy_tasks->{ 'database' }, "deploy task defined" );
is_deeply( $task->{ depends }, [ 'rt' ], "Dependancy is correct" );

$task->{ _sub }->( Fake->new( loaddb => 0 ));
is_deeply(
    \%ACTIONS,
    {},
    "no actions ran."
);

$task->{ _sub }->( Fake->new( loaddb => 1 ));
is_deeply(
    \%ACTIONS,
    {
        loaddb => 1,
        dropdb => 1,
        createdb => 1,
    },
    "correct actions ran."
);

%ACTIONS = ();
@ARGV = (qw/ database --drop --load 1 --create --dump 1/);
my $cmd = RTDevSys::Cmd->new();
$cmd->run();
is_deeply(
    \%ACTIONS,
    {
        dumpdb => 1,
        loaddb => 1,
        dropdb => 1,
        createdb => 1,
    },
    "All actions ran."
);

@ARGV = ( 'database' );
%ACTIONS = ();
$cmd = RTDevSys::Cmd->new();
$cmd->run();
is_deeply(
    \%ACTIONS,
    {},
    "no actions ran."
);
