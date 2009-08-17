use strict;
use warnings;

use Test::More tests => 1;
use RTDevSys::Test;

BEGIN{ use_ok('RTDevSys::Cmd::Command::system'); }

__END__

sub run {
    my ($self, $opt, $args) = @_;
    my ( $path ) = @$args;
    $path ||= RTDevSys->config->system_migrations;
    require RTDevSys::Workflows;
    RTDevSys::Workflows::run_migrations( 'system', 'db_version', $path );
}

add_deploy_task(
    'system',
    sub {
        require RTDevSys::Workflows;
        RTDevSys::Workflows::run_migrations( 'system', 'db_version', RTDevSys->config->system_migrations );
    },
    depends => 'config'
);

1;
