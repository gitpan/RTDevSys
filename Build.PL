#!/usr/bin/perl
use Module::Build;

my $build = Module::Build->new(
    module_name => 'RTDevSys',
    license => 'gpl',
    requires => {
        'Cwd' => '3.30',
        'Test::Exception' => '0.27',
        'Test::More' => '0.86',
        'YAML::Syck' => '1.07',
        'Exporter' => '5.63',
        'ExtUtils::MakeMaker' => '6.50',
        'Moose' => '0.79',
        'MooseX::ClassAttribute' => '0.08',
        'MooseX::App::Cmd' => '0.04',
        'Fey' => '0.28',
        'Fey::Loader' => '0.10',
        'Fey::ORM' => '0.24',
        'Fey::DBIManager' => '0.10',
        'File::Path' => '2.07',
        'File::Temp' => '0.21',
        'Module::Build' => '0.33',
        'Module::Install' => '0.88',
        'String::Diff' => '0.04',
        'DBD::Pg' => '2.13.1',
        'DBD::SQLite' => '1.25',
        'Data::Dumper' => 0,
    },
    build_requires => {
        'Test::More' => 0.8,
    },
);

$build->create_build_script;
