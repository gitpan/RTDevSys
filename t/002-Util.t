use strict;
use warnings;

use Test::More tests => 11;
use Test::Exception;
use RTDevSys::Test;
use RTDevSys;

BEGIN{ use_ok('RTDevSys::Util'); }
RTDevSys::Util->import();

dies_ok { run_command( "THISISNOTAREALCOMMAND >/dev/null 2>&1" )} "dies when a command does not exit properly.";
lives_ok{ run_command( "echo 'hi' >/dev/null" )} "Do not die when command exits cleanly";

is(
    RTDevSys::Util::_initial_data_command( "MyFile" ),
    RTDevSys::RTHOME() . "/sbin/rt-setup-database --action insert --datafile 'MyFile' --dba-password 'NONE'",
    "initialdata command is fine."
);

is( RTDevSys::strip_lead( '000-blah'), 'blah', "strip leading #-" );
is( RTDevSys::strip_lead( 'blah'), 'blah', "Nothing to strip" );

is_deeply(
    include_list(),
    [
        $ENV{HOME} . "/RTDevSys/lib/perl5",
        RTDevSys->RTHOME . "/etc",
        RTDevSys->RTHOME . "/lib",
        RTDevSys->RTHOME . "/local/lib",
        "lib",
        glob( RTDevSys->RTHOME . "/local/plugins/*/lib"),
        $ENV{ PERL5LIB } || "",
    ],
    "include list is complete"
);

is(
    workflow_path( 'FAKE_W' ),
    '001-FAKE_W',
    "Found workflow path"
);

is_deeply(
    workflow_list(),
    [
        'FAKE_W',
        'DISABLED_EXP',
        'DISABLED_IMP',
        'NO_MIGRATIONS',
        'MIGRATIONS',
    ],
    "List of workflows"
);

is_deeply(
    workflow_list( 1 ),
    [
        '001-FAKE_W',
        '002-DISABLED_EXP',
        '003-DISABLED_IMP',
        '004-NO_MIGRATIONS',
        '005-MIGRATIONS',
    ],
    "List of workflows with lead"
);

is_deeply(
    plugin_list(),
    [
        'DISABLED_P',
        'FAKE_P',
        'FAKE_P2',
    ],
    "List of plugins"
);
