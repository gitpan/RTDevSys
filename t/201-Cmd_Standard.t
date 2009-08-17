use strict;
use warnings;

use Test::More tests => 12;
use RTDevSys::Test;

BEGIN {

    $INC{ 'RTDevSys/Cmd/Command/Fake.pm' } = __FILE__;

    @ARGV = (
        'fake',
        '--user' => 'user',
        '--group' => 'group',
        '--build' => 'build',
        '--rthome' => 'rthome',
        '--dbuser' => 'dbuser',
        '--dbport' => 5555,
        '--dbhost' => 'dbhost',
        '--dbname' => 'dbname',
        '--webuser' => 'webuser',
        '--webgroup' => 'webgroup',
        '--password' => 'password',
        '--versions_file' => 'versions_file',
    );

    package RTDevSys::Cmd::Command::Fake;
    use strict;
    use warnings;
    use RTDevSys;
    use RTDevSys::Util;
    use RTDevSys::DB;
    use RTDevSys::Plugins;
    use RTDevSys::Cmd::Command::rt;
    use RTDevSys::Workflows;

    use Moose;
    extends qw(MooseX::App::Cmd::Command);

    with 'RTDevSys::Cmd::Roles::Standard';

    sub abstract { "Test command" }

    sub usage_desc {
        my ($self) = @_;
        my ($command) = $self->command_names;
        return "%c $command %o"
    }

    sub run {
        my ($self, $opt, $args) = @_;
    }
}

use RTDevSys::Cmd;
my $cmd = RTDevSys::Cmd->new();
$cmd->run();

is( RTDevSys->RTHOME, 'rthome', 'variable rthome sets RTDevSys->RTHOME' );
is( RTDevSys->RT_DB_PASSWORD, 'password', 'variable password sets RTDevSys->RT_DB_PASSWORD' );
is( RTDevSys->RT_USER, 'user', 'variable user sets RTDevSys->RT_USER' );
is( RTDevSys->RT_GROUP, 'group', 'variable group sets RTDevSys->RT_GROUP' );
is( RTDevSys->RT_WEB_USER, 'webuser', 'variable webuser sets RTDevSys->RT_WEB_USER' );
is( RTDevSys->RT_WEB_GROUP, 'webgroup', 'variable webgroup sets RTDevSys->RT_WEB_GROUP' );
is( RTDevSys->VERSIONS_FILE, 'versions_file', 'variable versions_file sets RTDevSys->VERSIONS_FILE' );
is( RTDevSys->BUILD, 'build', 'variable build sets RTDevSys->BUILD' );
is( RTDevSys->RT_DB_USER, 'dbuser', 'variable dbuser sets RTDevSys->RT_DB_USER' );
is( RTDevSys->RT_DB_PORT, 5555, 'variable dbport sets RTDevSys->RT_DB_PORT' );
is( RTDevSys->RT_DB_HOST, 'dbhost', 'variable dbhost sets RTDevSys->RT_DB_HOST' );
is( RTDevSys->RT_DB, 'dbname', 'variable dbname sets RTDevSys->RT_DB' );
