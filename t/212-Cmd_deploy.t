use strict;
use warnings;

use Test::More tests => 3;
use RTDevSys::Test;

BEGIN{ use_ok('RTDevSys::Cmd::Command::deploy'); }

my %RAN;

my $tasks = {
    first => {
        _sub => sub { $RAN{ 'first' }++ }
    },
    second => {
        depends => [ 'first' ],
        _sub => sub {
            die( "Dependancy not met" ) unless $RAN{ 'first' };
            $RAN{ 'second' }++
        }
    },
    third => {
        depends => [ 'second' ],
        _sub => sub {
            die( "Dependancy not met" ) unless $RAN{ 'second' };
            $RAN{ 'third' }++
        }
    },
    fourth => {
        depends => [ 'third' ],
        _sub => sub {
            die( "Dependancy not met" ) unless $RAN{ 'third' };
            $RAN{ 'fourth' }++
        }
    },
};

is_deeply(
    RTDevSys::Cmd::Command::deploy::tasksort( $tasks ),
    [ qw/first second third fourth/ ],
    "tasksort sorts tasks by dependancy."
);

RTDevSys->deploy_tasks( $tasks );

RTDevSys::Cmd::Command::deploy::run( {} );
is_deeply(
    \%RAN,
    {
        first => 1,
        second => 1,
        third => 1,
        fourth => 1,
    },
    "All tasks ran"
);
