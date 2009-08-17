use strict;
use warnings;

use Test::More tests => 64;
use Test::Exception;
use YAML::Syck;
use RTDevSys::Test;
use RTDevSys;

BEGIN{ use_ok('RTDevSys::Versions'); }
RTDevSys::Versions->import();

RTDevSys->VERSIONS_FILE( 't/res/versions.yaml' );
is_deeply(
    RTDevSys::Versions::VERSIONS(),
    LoadFile( 't/res/versions.yaml' ),
    "Loaded correct file"
);

is_deeply(
    RTDevSys::Versions::VERSIONS(),
    {
        'system' => {
            db_version => {
                stable => 5,
                demo => 9,
            }
        },
        plugin => {
            FAKE_P => {
                stable => 0,
                demo => 1,
            },
            FAKE_P2 => {
                stable => 1,
                demo => 1,
            },
        },
        workflow => {
            FAKE_W => {
                stable => 2,
                demo => 5,
            },
            DISABLED_EXP => {
                stable => 1,
                demo => 1,
                disable => 1,
            },
            DISABLED_IMP => undef,
            NO_MIGRATIONS => {
                stable => 0,
                demo => 0,
            },
            MIGRATIONS => {
                stable => 0,
                demo => 0,
            },
        }
    },
    "File has correct datastructure"
);

is_deeply(
    item_version( 'workflow', '000-FAKE_W' ),
    {
        stable => 2,
        demo => 5,
    },
    "Can get item versions"
);

is( item_disabled( 'workflow', 'DISABLED_EXP' ), 1, "Explicetly disabled items are disabled" );
is( item_disabled( 'workflow', 'DOES_NOT_EXIST' ), 1, "missing items are disabled" );
is( item_disabled( 'workflow', 'DISABLED_IMP' ), 1, "items with no data are disabled" );
is( item_disabled( 'workflow', 'FAKE_W' ), 0, "undisabled workflow is not disabled" );

is( stable_version( 'workflow', 'FAKE_W' ), 2, "Correct stable version of workflow" );
is( stable_version( 'plugin', 'FAKE_P' ), 0, "Correct stable version of plugin" );
is( stable_version( 'system', 'db_version' ), 5, "Correct stable version of system" );

is( demo_version( 'workflow', 'FAKE_W' ), 5, "Correct demo version of workflow" );
is( demo_version( 'plugin', 'FAKE_P' ), 1, "Correct demo version of plugin" );
is( demo_version( 'system', 'db_version' ), 9, "Correct demo version of system" );

RTDevSys->BUILD( 'stable' );
is( indicated_version( 'workflow', 'FAKE_W' ), 2, "Correct indicated version of workflow" );
is( indicated_version( 'plugin', 'FAKE_P' ), 0, "Correct indicated version of plugin" );
is( indicated_version( 'system', 'db_version' ), 5, "Correct indicated version of system" );
is( can_install_plugin( 'FAKE_P' ), 0, "Cannot install plugin in stable" );
is( can_install_plugin( 'FAKE_P2' ), 1, "Can install plugin in stable" );
is( RTDevSys::Versions::_can_install_workflow( 'workflow', 'FAKE_W', 3 ), 0, "Cannot go above stable version" );
is( RTDevSys::Versions::_can_install_workflow( 'workflow', 'FAKE_W', 2 ), 1, "Can install stable version" );
is( RTDevSys::Versions::_can_install_workflow( 'workflow', 'FAKE_W', 1 ), 1, "Can install < stable version" );
is(
    can_install_workflow( 'FAKE_W', 3 ),
    RTDevSys::Versions::_can_install_workflow( 'workflow', 'FAKE_W', 3 ),
    "Delegated"
);
is(
    can_install_workflow( 'FAKE_W', 2 ),
    RTDevSys::Versions::_can_install_workflow( 'workflow', 'FAKE_W', 2 ),
    "Delegated"
);
is(
    can_install_workflow( 'FAKE_W', 1 ),
    RTDevSys::Versions::_can_install_workflow( 'workflow', 'FAKE_W', 1 ),
    "Delegated"
);
is( RTDevSys::Versions::_can_install_workflow( 'system', 'db_version', 6 ), 0, "Cannot go above stable version" );
is( RTDevSys::Versions::_can_install_workflow( 'system', 'db_version', 5 ), 1, "Can install stable version" );
is( RTDevSys::Versions::_can_install_workflow( 'system', 'db_version', 4 ), 1, "Can install < stable version" );
is(
    can_install_system( 6 ),
    RTDevSys::Versions::_can_install_workflow( 'system', 'db_version', 6 ),
    "Delegated"
);
is(
    can_install_system( 5 ),
    RTDevSys::Versions::_can_install_workflow( 'system', 'db_version', 5 ),
    "Delegated"
);
is(
    can_install_system( 4 ),
    RTDevSys::Versions::_can_install_workflow( 'system', 'db_version', 4 ),
    "Delegated"
);

RTDevSys->BUILD( 'demo' );
is( indicated_version( 'workflow', 'FAKE_W' ), 5, "Correct indicated version of workflow" );
is( indicated_version( 'plugin', 'FAKE_P' ), 1, "Correct indicated version of plugin" );
is( indicated_version( 'system', 'db_version' ), 9, "Correct indicated version of system" );
is( can_install_plugin( 'FAKE_P' ), 1, "Can install plugin in demo" );
is( can_install_plugin( 'FAKE_P2' ), 1, "Can install plugin in demo" );
is( RTDevSys::Versions::_can_install_workflow( 'workflow', 'FAKE_W', 6 ), 0, "Cannot go above demo version" );
is( RTDevSys::Versions::_can_install_workflow( 'workflow', 'FAKE_W', 5 ), 1, "Can install demo version" );
is( RTDevSys::Versions::_can_install_workflow( 'workflow', 'FAKE_W', 4 ), 1, "Can install < demo version" );
is(
    can_install_workflow( 'FAKE_W', 6 ),
    RTDevSys::Versions::_can_install_workflow( 'workflow', 'FAKE_W', 6 ),
    "Delegated"
);
is(
    can_install_workflow( 'FAKE_W', 5 ),
    RTDevSys::Versions::_can_install_workflow( 'workflow', 'FAKE_W', 5 ),
    "Delegated"
);
is(
    can_install_workflow( 'FAKE_W', 4 ),
    RTDevSys::Versions::_can_install_workflow( 'workflow', 'FAKE_W', 4 ),
    "Delegated"
);
is( RTDevSys::Versions::_can_install_workflow( 'system', 'db_version', 10 ), 0, "Cannot go above demo version" );
is( RTDevSys::Versions::_can_install_workflow( 'system', 'db_version', 9 ), 1, "Can install demo version" );
is( RTDevSys::Versions::_can_install_workflow( 'system', 'db_version', 8 ), 1, "Can install < demo version" );
is(
    can_install_system( 10 ),
    RTDevSys::Versions::_can_install_workflow( 'system', 'db_version', 10 ),
    "Delegated"
);
is(
    can_install_system( 9 ),
    RTDevSys::Versions::_can_install_workflow( 'system', 'db_version', 9 ),
    "Delegated"
);
is(
    can_install_system( 8 ),
    RTDevSys::Versions::_can_install_workflow( 'system', 'db_version', 8 ),
    "Delegated"
);


RTDevSys->BUILD( 'devel' );
is( can_install_plugin( 'FAKE_P' ), 1, "Can install plugin in no build" );
is( can_install_plugin( 'FAKE_P2' ), 1, "Can install plugin in no build" );
is( RTDevSys::Versions::_can_install_workflow( 'workflow', 'FAKE_W', 1000 ), 1, "Can go way above demo version" );
is( RTDevSys::Versions::_can_install_workflow( 'workflow', 'FAKE_W', 6 ), 1, "Can go above demo version" );
is( RTDevSys::Versions::_can_install_workflow( 'workflow', 'FAKE_W', 5 ), 1, "Can install demo version" );
is( RTDevSys::Versions::_can_install_workflow( 'workflow', 'FAKE_W', 4 ), 1, "Can install < demo version" );
is(
    can_install_workflow( 'FAKE_W', 6 ),
    RTDevSys::Versions::_can_install_workflow( 'workflow', 'FAKE_W', 6 ),
    "Delegated"
);
is(
    can_install_workflow( 'FAKE_W', 5 ),
    RTDevSys::Versions::_can_install_workflow( 'workflow', 'FAKE_W', 5 ),
    "Delegated"
);
is(
    can_install_workflow( 'FAKE_W', 4 ),
    RTDevSys::Versions::_can_install_workflow( 'workflow', 'FAKE_W', 4 ),
    "Delegated"
);
is( RTDevSys::Versions::_can_install_workflow( 'system', 'db_version', 1000 ), 1, "Can go way above demo version" );
is( RTDevSys::Versions::_can_install_workflow( 'system', 'db_version', 10 ), 1, "Can go above demo version" );
is( RTDevSys::Versions::_can_install_workflow( 'system', 'db_version', 9 ), 1, "Can install demo version" );
is( RTDevSys::Versions::_can_install_workflow( 'system', 'db_version', 8 ), 1, "Can install < demo version" );
is(
    can_install_system( 10 ),
    RTDevSys::Versions::_can_install_workflow( 'system', 'db_version', 10 ),
    "Delegated"
);
is(
    can_install_system( 9 ),
    RTDevSys::Versions::_can_install_workflow( 'system', 'db_version', 9 ),
    "Delegated"
);
is(
    can_install_system( 8 ),
    RTDevSys::Versions::_can_install_workflow( 'system', 'db_version', 8 ),
    "Delegated"
);




