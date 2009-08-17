use strict;
use warnings;

use Test::More tests => 29;
use RTDevSys::Test;
use RTDevSys::Util;
use RTDevSys::DB;
use RTDevSys;

BEGIN{ use_ok('RTDevSys::Plugins'); }

my %ACTIONS;
{
    no strict 'refs';
    no warnings 'redefine';
    #temp override
    local *{ "RTDevSys::Plugins::install_plugins" } = sub { $ACTIONS{ install_plugins } = [ @_ ]};
    local *{ "RTDevSys::Plugins::load_plugins" } = sub { $ACTIONS{ load_plugins } = [ @_ ]};
    local *{ "RTDevSys::Plugins::config_plugins" } = sub { $ACTIONS{ config_plugins } = [ @_ ]};
    local *{ "RTDevSys::Plugins::clean_plugins" } = sub { $ACTIONS{ clean_plugins } = [ @_ ]};
    local *{ "RTDevSys::Plugins::run_command" } = sub { $ACTIONS{ run_command } = [ @_ ]};

    RTDevSys::Plugins::deploy();

    my $list = plugin_list();
    is_deeply(
        \%ACTIONS,
        {
            install_plugins => [ $list ],
            load_plugins    => [ $list ],
            config_plugins  => [ $list ],
            clean_plugins   => [ $list ],
        },
        "Deploy runs the correct functions"
    );

    RTDevSys::Plugins::plugin_command( 'A_Plugin', 'Blah' );
    is_deeply(
        $ACTIONS{ run_command },
        [ <<EOT ],
cd "t/res/plugins/A_Plugin";
Blah
EOT
        "Plugin command wraps command properly.",
    );
}

clean_plugins([ qw/FAKE_P FAKE_P2/ ]);
ok(( not -e "t/res/plugins/FAKE_P/installed"), "Plugin not installed" );
ok(( not -e "t/res/plugins/FAKE_P2/installed"), "Plugin not installed" );
ok( install_plugin( 'FAKE_P' ), "Plugin installs" );
ok( install_plugin( 'FAKE_P2' ), "Plugin installs" );
ok(( -e "t/res/plugins/FAKE_P/installed"), "Plugin was installed" );
ok(( -e "t/res/plugins/FAKE_P2/installed"), "Plugin was installed" );
clean_plugins([ qw/FAKE_P FAKE_P2/ ]);
ok(( not -e "t/res/plugins/FAKE_P/installed"), "Plugin clean" );
ok(( not -e "t/res/plugins/FAKE_P2/installed"), "Plugin clean" );

install_plugins([ 'FAKE_P', 'FAKE_P2' ]);
ok(( -e "t/res/plugins/FAKE_P/installed"), "Plugin was installed" );
ok(( -e "t/res/plugins/FAKE_P2/installed"), "Plugin was installed" );
clean_plugins([ qw/FAKE_P FAKE_P2/ ]);

ok(clean_plugin( qw/DISABLED_P/ ), "Plugin cleaned");
ok(( not -e "t/res/plugins/DISABLED_P/installed"), "Plugin not installed" );
ok(( not install_plugin( qw/DISABLED_P/ )), "Plugin won't install");
ok(( not -e "t/res/plugins/DISABLED_P/installed"), "Plugin still not installed" );
ok(clean_plugin( qw/DISABLED_P/ ), "Plugin cleaned");
ok(( not -e "t/res/plugins/DISABLED_P/installed"), "Plugin clean" );

override( 'RTDevSys::Plugins', 'load_initialdata', \%ACTIONS );
is( get_component_ver( 'plugin', 'FAKE_P' ), undef, "plugin not initialized" );
ok( load_plugin( 'FAKE_P' ), "Loading data for plugin" );
is( $ACTIONS{ 'load_initialdata' }->[0], "t/res/plugins/FAKE_P/etc/initialdata", "initialdata command" );
is( get_component_ver( 'plugin', 'FAKE_P' ), 1, "Plugin initialized" );
is( load_plugin( 'FAKE_P' ), undef, "data already loaded for plugin" );
is( load_plugin( 'FAKE_P2' ), undef, "No data to load" );
is( load_plugin( 'DISABLED_P' ), undef, "not loading disabled" );

is_deeply(
    config_plugins([ qw/FAKE_P FAKE_P2 DISABLED_P NOTREAL/ ]),
    [ qw/FAKE_P FAKE_P2/ ],
    "Only configuring enabled plugins"
);

ok( open( my $pconf, RTDevSys->RTHOME . "/etc/RT_SitePlugins.pm" ), "Open config file");
{
    local $/ = undef;
    is_deeply(
        <$pconf> . "\n",
        <<'EOT',
Set(@Plugins, qw(RTx::FAKE_P RTx::FAKE_P2));

1;
EOT
        "Config file is correct"
    );
}
close( $pconf );
