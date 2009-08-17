use strict;
use warnings;

use Test::More tests => 15;
use RTDevSys::Test;
use RTDevSys::Versions;
use RTDevSys::Util;
use RTDevSys::DB;
use RTDevSys;

BEGIN{ use_ok('RTDevSys::Workflows'); }

my %ACTIONS;

{
    no warnings 'redefine';
    no strict 'refs';
    for my $sub ( qw/add_cron del_cron load_initialdata run_command/ ) {
        *{ "RTDevSys::Workflows::$sub" } = sub { $ACTIONS{ $sub } = [@_] };
    }
}

for my $wf ( qw/MIGRATIONS NO_MIGRATIONS/ ) {
    %ACTIONS = ();
    is( get_component_ver( 'workflow', $wf ), undef, "Workflow is not initialized yet" );
    ok( initialize_workflow( $wf ), "Initialize workflow");
    is( get_component_ver( 'workflow', $wf ), 0, "Workflow is initialized" );
    is( initialize_workflow( $wf ), undef, "workflow already initialized" );
    is_deeply(
        \%ACTIONS,
        {
            load_initialdata => [ "t/res/workflows/" . workflow_path( $wf ) . "/data.pm" ],
        },
        "Loaded data"
    );
}

run_migrations( 'workflow', 'NO_MIGRATIONS' );
is( get_component_ver( 'workflow', 'NO_MIGRATIONS' ), 0, "No migrations were run" );

%ACTIONS = ();
ok( run_migrations( 'workflow', 'MIGRATIONS' ), "Run migrations");
is( get_component_ver( 'workflow', 'MIGRATIONS' ), 1, "Migrations were run" );
is_deeply(
    \%ACTIONS,
    {
        run_command => [
            "WORKING_DIR='t/res/workflows/005-MIGRATIONS/migrations/001-First' t/res/workflows/005-MIGRATIONS/migrations/001-First/update"
        ],
        load_initialdata => [
            "t/res/workflows/005-MIGRATIONS/migrations/001-First/initialdata"
        ],
        add_cron => [
            "t/res/workflows/005-MIGRATIONS/migrations/001-First/cron-add"
        ],
        del_cron => [
            "t/res/workflows/005-MIGRATIONS/migrations/001-First/cron-del"
        ],
    },
    "Loaded data, and ran update"
);

#TODO:
# * test that workflows don't run again
# * test that migrations don't run if they are disabled
# * test migrations that are out of version range
