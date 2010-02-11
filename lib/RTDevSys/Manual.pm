package RTDevSys::Manual;
use strict;
use warnings;

=pod

=head1 NAME

RTDevSys::Manual - The RTDevSys Manual.

=head1 EARLY VERSION WARNING

This is a very early version of RTDevSys. It is ready for use, and in fact is
being used. However there may be some API changes in the future. As well there
may be some missing, incomplete, or untested features.

=head1 DESCRIPTION

RTDevSys is a command line utility that will create and work with RT projects.
The primary idea behind RTDevSys is a way to develop an RT deployment without
simply installing RT and hacking against it and its database. To do this, the
RT project is seperated into several parts:

=head1 RT PROJECT COMPONENTS

=over 1

=item Vendor RT

This is the actual base RT code. A complete copy of the RT installation source
should be kept under the project directory. RT Source is usually placed into
vendor/rt

=item Patches

Sometimes a plugin, extention, or database change is not enough. Sometimes yo
uneed to patch RT. Patches could take a while to get into RT itself, and some
patches may be very project specific. RTDevSys lets you place patches into a
directory within the project, and it will take care of applying them at
deployment.

=item Plugins (Extentions)

When developing an RT project you will probably need to use, or even create,
several plugins. These are perl packages that usually start with RTx::. With
RTDevSys you will place plugins into a single directory and RTDevSys will take
care of installing and configuring them.

=item Workflows

Workflows are essentially whats initially loaded into the database. Queues,
Scrips, and other RT objects should be defined in workflows. You can have any
number of workflows, they can be seperated out in any way you wish. Workflows
are essentially just initialdata files collected into directories.

RTDevSys provides the advantage of version tracking. When RTDevSys installs
a workflow it records the name and version in the database. You can run
RTDevSys against a deployed database and not worry about loading the workflow
data multiple times. In addition you can create numbered migrations against a
workflow for upgrade purposes. Workflow migrations make developing and
maintaining RT deployments very smooth.

=item System

The system is essentially a workflow that is kept seperate from the others.
There is no difference between the system directory and a workflow directory.
The point is that this is where initialdata and migrations that are for the
whole system, as opposed to business logic, should go. An example would be if
you upgrade RT versions and need to run an RT script to handle that.

=item Migrations

These were briefly mentioned in the workflows section. Migrations are
directories containing a version number and a name. When deployed RTDevSys
records the latest version number to avoid re-applying a migration. A migration
folder can contain an 'update' script, which is simply any shell executable,
and/or an initialdata file which is a standard RT initialdata file.

=back

=head1 STARTING A PROJECT

    rtdevsys init myproject

This will create an RTDevSys project folder.

=over 4

=item myproject/RTDS_Config.pm

This is the project configuration file. The configuration file is written in
perl. The configuration file should define an RTDevSys::Config object, and
define at least one build within that config object. The code should return the
config object.

=item myproject/versions.yaml

The versions.yaml file controls what versions should be deployed on specific
builds. An example:

    ---
    #The system version
    system:
      db_version:
        stable: 0
        demo: 0

    #plugin versions
    plugin:
      MyPlugin:
        stable: 0
        demo: 1

    #workflow versions
    workflow:
      MyWorkflow:
        stable: 3
        demo: 5

MyWorkflow migrations up through 3 are stable, but migrations 5 and 6 are not
yet stable, this means that in the stable build deployment MyWorkflow will only
be updated to version 3, in the demo build deployment it will be updated up to
5. The MyPlugin plugin will be deployed in the demo build, but not in the
stable build. The base db_version will remain at the initial version which is
0.

In RTDevSys a plugin or workflow is disabled if it is unlisted, or if the
disable property is true. 0 refers to the initial version before any
migrations, it does not mean do not install.

Here are the rules specified in the file:

    # If a plugin or workflow is not listed it will be skipped
    # If disable: is true the workflow or plugin will be skipped
    # If stable: is missing then the plugin or workflow will not be installed in stable
    # If demo: is missing then it will default to stable
    # If both are missing it counts as disabled, use devel: 1 to enable it for
    # development
    # If nothing is listed it is the same as disable
    # Do not include any ###- prefix when listing workflows.

=item myproject/migrations/

The migrations/ folder contains all migrations against the main system. This is
for migrations that do not apply to a single workflow. Migrations are folders
that have this format: ###-Description. Each migration may have 1 or both of
the following files:

001-Migration/update - An executable file, perl, bash, binary, whatever. This
file will be run when the migration is run.

001-Migration/initialdata - A standard RT plugin initialdata file containing
data that should be loaded into the database.

Both files are optional, but at least one must be present.

No 2 migration folders should have the same number prefix, and all numbers
should be sequential integers. Skipping numbers will not cause any issues.

=item myproject/workflows/

Each folder within this one is a workflow. You can prefix workflows folders
with numbers if they need to be loaded in a specific order. Workflows should
contain one or more .pm files. Each .pm file within a workflow folder will be
loaded as a standard RT initialdata file.

Workflows may also have migrations. The workflows/MyWorkflow/migrations may
contain migration folders just like the system migrations. Please see the
system migrations section for details.

=item myproject/plugins/

Each folder within the plugins folder should be a standard RT plugin. This
means a real RT plugin that uses Module::Build::RTx.

=item myproject/vendor/

=item myproject/vendor/patches/

Place patches that should be applied against RT at deployment time in here.
Those prefixed with a number will be run, those without a number prefix will be
ignored.

Patches are applied at deployment, and unapplied afterwords.

=item myproject/vendor/rt/

Place the RT installation source here It is not provided with RTDevSys.

=back

=head1 DEPLOYMENT

myproject $ rtdevsys --help deploy
rtdevsys <command>

rtdevsys deploy [long options...] [build]
--loaddb             Load database from specified file.
--dbname             Database name (RT_DB)
--password           Database password (RT_DB_PASSWORD)
--versions_file      versions.yaml file to use
--user               RT/DB User (RT_USER)
--rthome             RT Installation Path (RTHOME)
--webuser            RT/DB User (RT_WEB_USER)
--dbport             Database port number (RT_DB_PORT)
--group              RT Group (RT_GROUP)
--dbuser             Database database user (RT_DB_USER)
--dbhost             Database Host (RT_DB_HOST)
--webgroup           RT Group (RT_WEB_GROUP)
--build              'stable', 'demo', or 'devel'
--initdb             Initialize a new RT database

To deploy a specific build use $ rtdevsys --build MYBUILD. Most of these
options should be self-explanitory, most are also configurable in the
RTDS_Config file per build. --initdb and --build are the only options you are
likely to need if you have a proper RTDS_Config.

=head1 IMPORTANT COMMANDS

    rtdevsys help <command>

    Available commands:

    commands:   list the application's commands
    help:       display a command's help screen

    database:   Manage the database
    deploy:     Deploy an RT installation
    init:       Initialize a project directory
    plugins:    Install, load, configure, and create plugins
    rt:         RT Installation
    run:        run a command with all the rt environment set
    server:     Control the rt standalone server
    system:     Runs system migrations
    test:       Test utilities.
    versions:   Displaye version info
    workflows:  Installs workflows and runs workflow migrations

=head1 TESTING

Usually I create a project Makefile that calls some long, but often needed
rtdevsys commands. Here is a copy of the testing section I usually use:

    pre-test:
    	rm -rf test-stderr.log

    test-workflows: pre-test
    	${RT_DEV_SYS} test --workflows 2>> test-stderr.log

    test-plugins: pre-test
    	${RT_DEV_SYS} test --plugins 2>> test-stderr.log

    test:
    	${RT_DEV_SYS} test --workflows --plugins

    test-rt:
    	${RT_DEV_SYS} rt --test

    reload-testdb:
    	${PERL} -e "use RTDevSys::DB; RTDevSys::DB::loaddb( '.test.psqlc', flags => '-c' );"

I plan to expand this section later, for now the above examples should show how
the rtdevsys testing tools are used. The last one will simply load the database
dump that is created prior to any tests.

=head1 USEFUL EXTENTIONS

These are not yet available on cpan. I will add them when I have figured out
the mechanics of Module::Install::RTx + CPAN when there is no RT installed on
the cpan testers hosts.

For now these can be found on my github page: http://github.com/exodist

=over 4

=item RTx::DevSys

This extention was originally part of RTDevSys. This extention will add several
commands to RTDevSys for manipulating the database, Using shredder, or
replacing email and passwords for development purposes. It also adds a simple
interface and testing helpers. I do not recommend using RTDevSys without it.

=item RTx::NNID

NNID stands for Non-Numeric ID. This extention will allow you to track,
maintain, and modify most objects stored in the RT database using code. NNID
files are very similar to initialdata files in that they define objects that go
into the database. The difference is that items are given a unique name, and
any changes to objects defined in the file can be synchronised to the database.
There is also a capture and dumper tool that will allow you to use NNID against
an already deployed RT.

=back

=head1 TODO

=over 4

=item RTDevSys commands to create an empty workflow or plugin.

=item RTDevSys commands to create an empty migration.

=cut

1;
