package RTDevSys::DB;

#{{{

=pod

=head1 NAME

RTDevSys::DB

=head1 EARLY VERSION WARNING

This is a very early version of RTDevSys. It is ready for use, and in fact is
being used. However there may be some API changes in the future. As well there
may be some missing, incomplete, or untested features. At the moment the
database commands only support postgres not mysql.

=cut

#}}}

use strict;
use warnings;

use RTDevSys;
use RTDevSys::Util;
use Carp;
use Moose;
use MooseX::ClassAttribute;

use base 'Exporter';

our @EXPORT = qw/update_component_ver get_component_ver/;
our @EXPORT_OK = qw/update_component_ver get_component_ver get_version version_db/;

my $CONNECTED = 0;
sub db_connect {
    return if $CONNECTED;
    eval 'require RTDevSys::DB::VersionTable';
    RTDevSys::DB::VersionTable->import();
    $CONNECTED++;
}

sub update_component_ver {
    my ( $component, $item, $version ) = @_;
    db_connect();
    die( "You must specify a version\n" ) unless defined( $version );
    if ( my $osversion = get_version( $component, $item )) {
        return $osversion->update( version => $version );
    }
    else {
        return RTDevSys::DB::VersionTable->insert(
            component => $component,
            item => $item,
            version => $version,
        );
    }
}

sub get_component_ver {
    my ( $component, $item ) = @_;
    db_connect();
    my $osversion = get_version( $component, $item );

    return undef unless $osversion;
    return $osversion->version;
}

sub get_version {
    my ( $component, $item ) = @_;
    db_connect();
    $item = strip_lead( $item );
    die( "You must specify a component\n" ) unless $component;
    die( "You must specify an item\n" ) unless $item;

    return RTDevSys::DB::VersionTable->new(
        component => $component,
        item => $item,
    );
}

sub dropdb {
    run_command( sql_command( 'drop', append => ' || exit 0' ));
}

sub createdb {
    run_command( sql_command( 'create' ));
}

sub dumpdb {
    my ( $name, @params ) = @_;
    run_command( sql_command( 'dump', file => $name, @params ));
}

sub loaddb {
    my ( $name, @params ) = @_;
    run_command( sql_command( 'load', file => $name, @params ));
}

sub mergedb {
    my ( $name, @params ) = @_;
    run_command( sql_command( 'merge', file => $name, append => '>& /dev/null', @params ));
}

sub sql_command {
    my $base = shift;
    my %params = @_ if @_;
    my $append = $params{ append } || "";
    my $file = $params{ file } || "";
    my $flags = $params{ flags } || "";

    my $driver = RTDevSys->RT_DB_DRIVER;
    my $sub = '_' . $driver . '_command';
    no strict 'refs';
    &$sub($base, $append, $file, $flags, %params);
}

sub _mysql_command {
    my ( $base, $append, $file, $flags, %params ) = @_;

    chomp( my $password = RTDevSys->RT_DB_PASSWORD );
    my $dbname = RTDevSys->RT_DB;
    $flags = " -P" . RTDevSys->RT_DB_PORT
                  . " -p$password"
                  . " -h" . RTDevSys->RT_DB_HOST
                  . " -u" . RTDevSys->RT_DB_USER
                  . " $flags";

    my %base_map = (
        'mysql' => 'mysql',
        'dump' => "mysqldump --add-drop-table $flags  $dbname > $file $append",
        'load' => "mysql $flags  $dbname < $file",
        'create' => "echo \"create database $dbname;\" | mysql $flags $append",
        'drop' => "echo \"drop database $dbname;\" | mysql $flags $append",
    );

    return $base_map{ $base } || die( "SQL command $base is not supported." );
}

sub _Pg_command {
    my ( $base, $append, $file, $flags, %params ) = @_;
    my %base_map = (
        'psql' => 'psql',
        'dump' => "pg_dump -Fc -x -O -f $file",
        'load' => "pg_restore -Fc -O -x -1 $file",
        'create' => 'createdb -E utf8',
        'drop' => 'dropdb',
        'merge' => "pg_restore -Fc -O -x $file",
    );
    my %flag_map = ( 'load' => ' -d ', 'merge' => ' -d ' );

    my $dbflag = $flag_map{ $base } || " ";
    $base = $base_map{ $base } || die( "SQL command $base is not supported." );

    chomp( my $password = RTDevSys->RT_DB_PASSWORD );
    my $command = "PGPASSWORD='$password'"
             . " $base"
             . " $flags "
             . " -U " . RTDevSys->RT_DB_USER
             . " -p " . RTDevSys->RT_DB_PORT
             . " -h " . RTDevSys->RT_DB_HOST
             . $dbflag . RTDevSys->RT_DB
             . " $append";
    return $command;
}

1;

__END__

=head1 AUTHORS

Chad Granum E<lt>chad@opensourcery.comE<gt>

Ryan Whitehurst E<lt>ryan@opensourcery.comE<gt>

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

