use strict;
use warnings;

use Test::More tests => 9;
use Test::Exception;
use RTDevSys::Test;
use RTDevSys;

use_ok('RTDevSys::DB');
use_ok('RTDevSys::DB::Schema');
use_ok('RTDevSys::DB::VersionTable');

my $CLASS = 'RTDevSys::DB';

ok( RTDevSys::DB::VersionTable->insert( component => 'test', item => 'test-1', version => '0'), "Able to create a version object");
is_deeply(
    RTDevSys::DB::get_version( qw/ test test-1 / ),
    {
        component => 'test',
        item => 'test-1',
        version => 0,
    },
    "Object is correct"
);

ok( update_component_ver( 'test', 'test-2', 0 ), "Create one with update.");
ok( RTDevSys::DB::get_version( qw/ test test-2 / ), "Found created item" );

update_component_ver( 'test', 'test-2', 2 );
is( RTDevSys::DB::get_version( qw/ test test-2 / )->version, 2, "version has been updated" );
is( get_component_ver( qw/ test test-2 /), 2, "get version works" );
