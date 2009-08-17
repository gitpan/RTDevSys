use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;
use RTDevSys;

BEGIN{ use_ok('RTDevSys::Test'); }

is( RTDevSys->RT_DB_DRIVER, "SQLite", "Correct db driver" );
ok( RTDevSys::DB::Schema->Schema->table( RTDevSys->config->versions_table ), "Table exists");
