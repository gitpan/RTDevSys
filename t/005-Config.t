use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;
use RTDevSys;
use RTDevSys::Test;

BEGIN{ use_ok('RTDevSys::Config'); }

my $config = RTDevSys->config;

is_deeply(
    [ $config->list_builds ],
    [ 'devel' ],
    "devel is listed"
);

ok( $config->add_build( 'fake' => { message => 'hi' }), "Create fake build");

is_deeply(
    [ $config->list_builds ],
    [ 'devel', 'fake' ],
    "fake is listed"
);

is_deeply(
    $config->get_build( 'fake' ),
    { message => 'hi' },
    "Retrieval"
)
