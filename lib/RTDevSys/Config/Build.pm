package RTDevSys::Config::Build;

#{{{

=pod

=head1 NAME

RTDevSys::Config::Build

=head1 EARLY VERSION WARNING

This is a very early version of RTDevSys. It is ready for use, and in fact is
being used. However there may be some API changes in the future. As well there
may be some missing, incomplete, or untested features. At the moment the
database commands only support postgres not mysql.

=cut

#}}}

use strict;
use warnings;

use Moose;

has 'RTHOME' => (
    isa => 'Str',
    is => 'rw',
);

has 'RT_DB' => (
    isa => 'Str',
    is => 'rw',
);

has 'RT_DB_HOST' => (
    isa => 'Str',
    is => 'rw',
);

has 'RT_DB_PORT' => (
    isa => 'Str',
    is => 'rw',
);

has 'RT_DB_USER' => (
    isa => 'Str',
    is => 'rw',
);

has 'RT_DB_DRIVER' => (
    isa => 'Str',
    is => 'rw',
);

has 'RT_DB_PASSWORD' => (
    is => 'rw',
);

has 'VERSIONS_FILE' => (
    isa => 'Str',
    is => 'rw',
);

has 'RT_USER' => (
    isa => 'Str',
    is => 'rw',
);

has 'RT_GROUP' => (
    isa => 'Str',
    is => 'rw',
);

has 'RT_WEB_USER' => (
    isa => 'Str',
    is => 'rw',
);

has 'RT_WEB_GROUP' => (
    isa => 'Str',
    is => 'rw',
);

has 'WEB_USER' => (
    isa => 'Str',
    is => 'rw',
);

has 'WEB_GROUP' => (
    isa => 'Str',
    is => 'rw',
);

has 'RT_CONF_PATH' => (
    isa => 'Str',
    is => 'rw',
);

1;

__END__

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

