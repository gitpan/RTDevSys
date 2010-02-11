package RTDevSys::Cmd::Roles::Standard;

#{{{

=pod

=head1 NAME

RTDevSys::Cmd::Roles::Standard - A role containing common attributes used in
all RTDevSys commands.

=head1 EARLY VERSION WARNING

This is a very early version of RTDevSys. It is ready for use, and in fact is
being used. However there may be some API changes in the future. As well there
may be some missing, incomplete, or untested features. At the moment the
database commands only support postgres not mysql.

=head1 DESCRIPTION

This role contains common attributes recognised by RTDevSys. This role should
be done by all the commands available to RTDevSys. When a command is run all
these attributes will be set if specified. When one of these attributes is set
it triggers the same attribute in the RTDevSys class to be set.

=head1 SYNOPSIS

    package RTDevSys::Cmd::Command::mycommand;
    use RTDevSys;
    use Moose;
    extends qw(MooseX::App::Cmd::Command);

    # The part that matters
    with 'RTDevSys::Cmd::Roles::Standard';

    ...

=head1 ATTRIBUTES

=over 4

=cut

#}}}

use Moose::Role;
use RTDevSys;

=item build

    $ rtdevsys --build stable
    $ rtdevsys --build demo
    $ rtdevsys --build devel

=cut

has build => (
    isa => "Str",
    is => "rw",
    #cmd_aliases => "b",
    documentation => "'stable', 'demo', or 'devel'",
    trigger => sub { shift( @_ ); RTDevSys->BUILD( @_ ) },
);

=item rthome

RT Installation Path (RTHOME)

=cut

has rthome => (
    isa => "Str",
    is => "rw",
    documentation => "RT Installation Path (RTHOME)",
    trigger => sub { shift( @_ ); RTDevSys->RTHOME( @_ ) },
);

=item password

Database password (RT_DB_PASSWORD)

=cut

has password => (
    isa => "Str",
    is => "rw",
    #cmd_aliases => "p",
    documentation => "Database password (RT_DB_PASSWORD)",
    trigger => sub { shift( @_ ); RTDevSys->RT_DB_PASSWORD( @_ ) },
);

=item user

RT/DB User (RT_USER)

=cut

has user => (
    isa => "Str",
    is => "rw",
    #cmd_aliases => "u",
    documentation => "RT/DB User (RT_USER)",
    trigger => sub { shift( @_ ); RTDevSys->RT_USER( @_ ) },
);

=item group

RT Group (RT_GROUP)

=cut

has group => (
    isa => "Str",
    is => "rw",
    #cmd_aliases => "g",
    documentation => "RT Group (RT_GROUP)",
    trigger => sub { shift( @_ ); RTDevSys->RT_GROUP( @_ ) },
);

=item webuser

RT/DB User (RT_WEB_USER)

=cut

has webuser => (
    isa => "Str",
    is => "rw",
    #cmd_aliases => "u",
    documentation => "RT/DB User (RT_WEB_USER)",
    trigger => sub { shift( @_ ); RTDevSys->RT_WEB_USER( @_ ) },
);

=item webgroup

RT Group (RT_WEB_GROUP)

=cut

has webgroup => (
    isa => "Str",
    is => "rw",
    #cmd_aliases => "g",
    documentation => "RT Group (RT_WEB_GROUP)",
    trigger => sub { shift( @_ ); RTDevSys->RT_WEB_GROUP( @_ ) },
);

=item versions_file

versions.yaml file to use

=cut

has versions_file => (
    isa => "Str",
    is => "rw",
    #cmd_aliases => "v",
    documentation => "versions.yaml file to use",
    trigger => sub { shift( @_ ); RTDevSys->VERSIONS_FILE( @_ ) },
);

=item dbuser

Database database user (RT_DB_USER)

=cut

has dbuser => (
    isa => "Str",
    is => "rw",
    documentation => "Database database user (RT_DB_USER)",
    trigger => sub { shift( @_ ); RTDevSys->RT_DB_USER( @_ ) },
);

=item dbdriver

Database database user (RT_DB_DRIVER)

=cut

has dbdriver => (
    isa => "Str",
    is => "rw",
    documentation => "Database database user (RT_DB_DRIVER)",
    trigger => sub { shift( @_ ); RTDevSys->RT_DB_DRIVER( @_ ) },
);


=item dbport

Database port number (RT_DB_PORT)

=cut

has dbport => (
    isa => "Int",
    is => "rw",
    #cmd_aliases => ["t" | "P"],
    documentation => "Database port number (RT_DB_PORT)",
    trigger => sub { shift( @_ ); RTDevSys->RT_DB_PORT( @_ ) },
);

=item dbhost

Database Host (RT_DB_HOST)

=cut

has dbhost => (
    isa => "Str",
    is => "rw",
    #cmd_aliases => ["s", "h"],
    documentation => "Database Host (RT_DB_HOST)",
    trigger => sub { shift( @_ ); RTDevSys->RT_DB_HOST( @_ ) },
);

=item dbname

Database name (RT_DB)

=cut

has dbname => (
    isa => "Str",
    is => "rw",
    #cmd_aliases => "d",
    documentation => "Database name (RT_DB)",
    trigger => sub { shift( @_ ); RTDevSys->RT_DB( @_ )},
);


1;

__END__

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

