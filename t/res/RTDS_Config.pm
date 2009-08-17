package RTDS_Config;
use strict;
use warnings;
use RTDevSys::Config;
use RTDevSys::Config::Build;
use File::Temp qw/tempdir/;

our $tmp = tempdir( 'test-XXXX', DIR=> "t", CLEANUP => 1 );

my $config = RTDevSys::Config->new(
    rt          => "t/res/vendor/rt",
    patches     => "t/res/vendor/patches",
    workflows   => "t/res/workflows",
    plugins     => "t/res/plugins",
    versions_table => "devsys_versions",
    system_migrations => "t/res/migrations",
);

$config->add_build(
    devel => RTDevSys::Config::Build->new(
        RTHOME       => "$tmp/dev/rt3",
        RT_DB           => "$tmp/test_rt_db",
        RT_DB_DRIVER    => "SQLite",
        RT_DB_PASSWORD  => 'NONE',
        RT_DB_HOST   => "",
        RT_DB_PORT   => "",
        RT_DB_USER   => $ENV{ USER },
        RT_USER      => $ENV{ USER },
        RT_GROUP     => "users",
        RT_WEB_USER  => $ENV{ USER },
        RT_WEB_GROUP => "users",
        WEB_USER     => $ENV{ USER },
        WEB_GROUP    => "users",
        VERSIONS_FILE   => 't/res/versions.yaml',
        RT_CONF_PATH => "$tmp/rttest"
    )
);

return $config;
