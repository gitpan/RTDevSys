package RTDevSys::DB::Schema;
use strict;
use warnings;

use Fey::Loader;
use Fey::ORM::Schema;
use Fey::DBIManager::Source;

my $driver = RTDevSys->RT_DB_DRIVER;
my $db   = RTDevSys->RT_DB;
my $host = RTDevSys->RT_DB_HOST;
my $port = RTDevSys->RT_DB_PORT;
my $user = RTDevSys->RT_DB_USER;
my $pass = RTDevSys->RT_DB_PASSWORD;

my $dsn = "dbi:$driver:dbname=$db;";
$dsn .= "host=$host;" if $host;
$dsn .= "port=$port;" if $port;
my $source = Fey::DBIManager::Source->new(
    name => 'main',
    dsn => $dsn,
    username => $user,
    password => $pass,
);

my $schema = Fey::Loader->new( dbh => $source->dbh )->make_schema;
my $table_name = RTDevSys->config->versions_table;
my $table = $schema->table( $table_name );
unless( $table ) {
    my $dbh = $source->dbh;
    $dbh->do( <<EOT );
CREATE TABLE $table_name(
    component TEXT,
    item TEXT,
    version NUMERIC,
    PRIMARY KEY( component, item )
);
EOT

    #FIXME refactor to use RTDevSys::DB::VersionTable
    for my $item ( ['RTDevSys', 'db_version', 1], ['system', 'db_version', 0] ) {
        my $sth = $dbh->prepare("INSERT INTO $table_name( component, item, version ) VALUES( ?,?,? )");
        $sth->execute( @$item );
    }

    $schema = Fey::Loader->new( dbh => $source->dbh )->make_schema;
}

has_schema( $schema );

__PACKAGE__->DBIManager->add_source( $source );

1;

__END__

=pod

=head1 NAME

RTDevSys::DB::Schema - Fey Schema class for RTDevSys versioning table.

=head1 EARLY VERSION WARNING

This is a very early version of RTDevSys. It is ready for use, and in fact is
being used. However there may be some API changes in the future. As well there
may be some missing, incomplete, or untested features. At the moment the
database commands only support postgres not mysql.

=head1 DESCRIPTION

This class generates the Schema necessary for Fey::ORM to work with the stored
versioning information. See Fey::ORM::Schema for more details.

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

