package RTDevSys::DB::VersionTable;
use strict;
use warnings;

use Fey::ORM::Table;
use RTDevSys::DB::Schema;
use Fey::Object::Iterator::FromSelect;

has_table( RTDevSys::DB::Schema->Schema->table( RTDevSys->config->versions_table ));

sub iterator {
    my $class = shift;
    my $select = $class->SchemaClass()->SQLFactoryClass()->new_select();

    $select->select( $class->Table )->from( $class->Table );

    my $dbh = $class->_dbh( $select );

    return Fey::Object::Iterator::FromSelect->new(
        select => $select,
        classes => [ $class->meta()->ClassForTable( $class->Table )],
        dbh => $dbh,
        bind_params => [ $select->bind_params ],
    );
}

sub get_all {
    my $class = shift;
    $class->iterator->all;
}

1;

__END__

=pod

=head1 NAME

RTDevSys::DB::VersionTable - Class for accessing stored versioning information.

=head1 EARLY VERSION WARNING

This is a very early version of RTDevSys. It is ready for use, and in fact is
being used. However there may be some API changes in the future. As well there
may be some missing, incomplete, or untested features. At the moment the
database commands only support postgres not mysql.

=head1 DESCRIPTION

Class for handling stored version information specific to RTDevSys installed
plugins and workflows. Each row in the versions table is treated as an object.
This class is built using Fey::ORM::Table.

=head1 CLASS METHODS

See Fey::Object::Table which is the base class for Fey::ORM objects generated
based on a table.

=over 4

=item iterator()

Returns an iterator for all objects in the table.

=item get_all()

returns a list of all objects in the table.

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

