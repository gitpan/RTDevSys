use strict;
use warnings;

use Test::More 'no_plan';
use RTDevSys::Test;
use RTDevSys::Cmd;
use YAML::Syck;
use File::Temp qw/tempdir/;

BEGIN{ use_ok('RTDevSys::Cmd::Command::init'); }

my $tmp = tempdir( 'project-XXXX', DIR => $RTDS_Config::tmp, CLEANUP => 1 );

ok(( not -d "$tmp/$_" ), "dir: $_ does not already exist")
    for qw| vendor vendor/rt vendor/patches workflows plugins migrations |;
ok(( not -f "$tmp/$_" ), "file: $_ doe not already exist.")
    for qw| RTDS_Config.pm versions.yaml |;

@ARGV = ( 'init', "$tmp" );
my $cmd = RTDevSys::Cmd->new();
$cmd->run();

ok(( -d "$tmp/$_" ), "dir: $_ created")
    for qw| vendor vendor/rt vendor/patches workflows plugins migrations |;
ok(( -f "$tmp/$_" ), "file: $_ created")
    for qw| RTDS_Config.pm versions.yaml |;

my $config = eval 'require "$tmp/RTDS_Config.pm"';
ok(( not $@ ), "RTDS Config file compiled fine." );
ok( $config, "RTDS Config file returns a config object" );

ok( my $versions = LoadFile( "$tmp/versions.yaml" ), "Can load versions");
is( ref $versions, 'HASH', "versions file loads as a hashref" );
