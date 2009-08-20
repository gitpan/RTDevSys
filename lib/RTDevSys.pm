package RTDevSys;
use strict;
use warnings;
use MooseX::ClassAttribute;
use RTDevSys::Util;
use RTDevSys::Config;
use RTDevSys::Config::Build;
use Carp;

our $VERSION = 0.04;

#{{{ Steal STDOUT before RT can.
our $STDOUT;
BEGIN {
    open( $STDOUT, ">&STDOUT" ) || die ("Could not copy STDOUT\n");
}

sub stdout {
    return $STDOUT;
}
#}}}

our @DEFVARS = (qw/ RT_DB RT_DB_DRIVER RT_DB_HOST RT_DB_PORT RT_DB_USER
RT_DB_PASSWORD RT_USER RT_GROUP RT_WEB_USER RT_WEB_GROUP VERSIONS_FILE
WEB_USER WEB_GROUP RT_CONF_PATH /);

our @VARS = ( @DEFVARS, qw/RTHOME BUILD/ );

use base 'Exporter';
our @EXPORT = qw/ stdout add_deploy_task /;
our @EXPORT_OK = (@EXPORT, qw/local_env/);

my $defsub = sub {
    my ($var, $default) = @_;
    return $ENV{ $var } if $ENV{ $var };
    unless( RTDevSys->config ) {
        warn ("Cannot find RTDS_Config.pm\n") unless -e 'RTDS_Config.pm';
        my $config = eval { require 'RTDS_Config.pm' };
        return $default if ( $@ || !$config );
        RTDevSys->config( $config );
    };
    my $def = RTDevSys->config->get_build( RTDevSys->BUILD )->$var;
    return $def->() if ref $def eq 'CODE';
    return $def;
};

for my $var ( @DEFVARS ) {
    class_has $var => (
        is => 'rw',
        isa => 'Str',
        lazy => 1,
        default => sub { $defsub->( $var, @_ ) },
    );
}

class_has RTHOME => (
    is => 'rw',
    isa => 'Str',
    lazy => 1,
    default => sub { $defsub->( 'RTHOME', '/var/rt3', @_ ) },
    trigger => sub {
        RTDevSys::Util::add_inc();
    }
);

class_has BUILD => (
    is => 'rw',
    isa => 'Str',
    lazy => 1,
    default => sub {
        return $ENV{ BUILD } if $ENV{ BUILD };
        return 'devel';
    }
);

class_has config => (
    is => 'rw',
    isa => 'RTDevSys::Config',
);

class_has rootdir => (
    is => 'rw',
    isa => 'Str',
    default => sub { chomp( my $a = `pwd` ); $a },
);

class_has deploy_tasks => (
    is => 'rw',
    isa => 'HashRef',
    default => sub {{}},
);

sub local_env {
    my $out_env = {
        %ENV,
        PERL5LIB => join( ':', @{ RTDevSys::Util::include_list() }),
        # RT is inconsistant, needs these for tests
        RT_DBA_USER => RTDevSys->RT_DB_USER,
        RT_DBA_PASSWORD => RTDevSys->RT_DB_PASSWORD,
        map { $_ => (RTDevSys->$_ || "" )} @VARS
    };
    return $out_env;
}

sub add_deploy_task {
    my ( $task, $sub, %params ) = @_;
    __PACKAGE__->deploy_tasks->{ $task } = { %params, _sub => $sub };
}

1;

__END__

=pod

=head1 NAME

RTDevSys - A development, deployment, and management system for RT
installations.

=head1 EARLY VERSION WARNING

This is a very early version of RTDevSys. It is ready for use, and in fact is
being used. However there may be some API changes in the future. As well there
may be some missing, incomplete, or untested features. At the moment the
database commands only support postgres not mysql.

=head1 DESCRIPTION

This module is the heart of RTDevSys. Through this class all other modules
access information about the RT Project being developed or deployed. This
module is not an object, it exports a couple functions, and provides a few
class methods. In the future this class may be refactored into a singleton.

This class is your one stop shop for all important variables and paths. All key
variables are defined in one of the ways. First if the matching environment
variable is set than that is used, If no environment variable is defined then
it will try to get the variable fromt he config file (RTDS_Config.pm). The
third way is for the variable to be set by another library. This is most
commonly done in commands via flags. (see RTDevSys::Cmd::Roles::Standard)

=head1 SYNOPSIS

=over 4

=item Command line interface

    $ rtdevsys deploy --build stable
    $ rtdevsys help deploy
    $ rtdevsys help
    $ rtdevsys plugins --install RTx::MyExt
    $ rtdevsys database --dump mydump.psqlc

See rtdevsys help <command> for more details.

=back

=head1 CLASS METHODS

=over 4

=item config()

Returns the RTDevSys::Config object laoded from RTDS_Config.pm

=item deploy_tasks()

Returns the hash of deployment tasks.

    {
        taskA => { _sub => sub { ... }},
        taskB => { _sub => sub { ... }},
    }

=item rootdir()

Returns the project root directory.

=back

=head1 ENVIRONMENT VARIABLES

All environment variables are class methods. They can be used like this:

    RTDevSys->RTHOME(); #retrive the RTHOME variable
    RTDevSys->RTHOME( '/opt/rt3' ); #Set the RTHOME variable.

The first time a variable is read, if it has not been set already, it will
obtain a default value either through the envuironment variable, or the config
file.

=over 4

=item RTHOME

The RT installation destination. This matches RT's RTHOME variable.

=item BUILD

Which type of build to deploy: devel, demo, or stable. See RTDevSys.conf and
RTDevSys::Build for details about builds.

=item VERSIONS_FILE

Path to a yaml file containing information about which module and plugin
versions will be installed in which build. Default is ./versions.yaml

=item RT_CONF_PATH

Path where RT_SiteConfig.pm can be found, or should be installed upon
deployment.

=item OTHER ENVIRONMENT VARIABLES

RT_DB, RT_DB_DRIVER, RT_DB_HOST, RT_DB_PORT, RT_DB_USER, RT_DB_PASSWORD,
RT_USER, RT_GROUP, RT_WEB_USER, RT_WEB_GROUP, WEB_USER, WEB_GROUP

For the most part these should be self-explanitory. They also mostly line up
with RT's recognised variables.

=back

=head1 EXPORTED OR EXPORTABLE FUNCTIONS

=over 4

=item stdout()

Returns a scalar filehandle for STDOUT. This is captured at module load time.
This is useful if you have to init RT in a module usinf RTDevSys and want to
write to STDOUT, which RT steals.

=item add_deploy_task()

Add tasks to the list of tasks that get run on deployment. Usually you call
this in a custom RTDevSys::Cmd::Command:: class.

    add_deploy_task MyTask => sub { ... };

    # This form is supported, but currently the parameters are not used for
    # anything.
    add_deploy_task MyTask2 => (
        sub { ... },
        ParamA => 'value',
        ParamB => 'value2',
    );

=item local_env()

*Not exported by default*

returns a hash containing %ENV with all the RTDevSys environment variables
added in. This is useful if you want to run a command with the environment
variables present:

    {
        local %ENV = %{ local_env() };
        system( ... )
    }

=back

=head1 AUTHORS

Chad Granum E<lt>chad@opensourcery.comE<gt>

=head1 COPYRIGHT

Copyright 2009 OpenSourcery, LLC.

This file is part of RTDevSys

RTDevSys is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

RTDevSys is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with RTDevSys.  If not, see <http://www.gnu.org/licenses/>.

=cut

