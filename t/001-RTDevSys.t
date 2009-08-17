use strict;
use warnings;

use Test::More tests => 7;
use RTDevSys::Test;

BEGIN{ use_ok('RTDevSys'); }
RTDevSys->import( 'add_deploy_task' );

is( stdout(), $RTDevSys::STDOUT, "STDOUT" );
ok( defined( stdout()), "STDOUT is defined." );

my $localenv = RTDevSys::local_env;

my $tmp = $RTDS_Config::tmp;
is(
    ( grep { $localenv->{ PERL5LIB } =~ m/^$_:|:$_:|:$_$|^$_$/ }
        "$tmp/dev/rt3/lib", "$tmp/dev/rt3/local/lib", "lib"),
    3,
    "Proper paths are present"
);

use Data::Dumper;
is_deeply(
    {
        %$localenv,
        PERL5LIB => undef,
    },
    {
        %ENV,
        PERL5LIB => undef,
        VERSIONS_FILE => 't/res/versions.yaml',
        BUILD => 'devel',
        RT_DBA_USER => $ENV{ USER },
        RT_DBA_PASSWORD => 'NONE',
        map { $_ => RTDevSys->config->get_build( RTDevSys->BUILD )->$_ } ( grep { $_ ne 'BUILD' } @RTDevSys::VARS )
    },
    "Exporting variables for env."
);

is( RTDevSys::VERSIONS_FILE(), 't/res/versions.yaml', "default versions.yaml" );

my $test_sub = sub { "test" };

add_deploy_task(
    'first',
    $test_sub,
    paramA => 'a',
    paramB => 'b',
);
add_deploy_task(
    'second',
    $test_sub,
    paramC => 'c',
    paramD => 'd',
);

is_deeply(
    RTDevSys->deploy_tasks,
    {
        first => {
            _sub => $test_sub,
            paramA => 'a',
            paramB => 'b',
        },
        second => {
            _sub => $test_sub,
            paramC => 'c',
            paramD => 'd',
        },
    },
    'deploy tasks recorded properly'
);
