package RTDevSys::Cron;

#{{{

=pod

=head1 NAME

package RTDevSys::Cron - Do not use this!

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

use base 'Exporter';
our @EXPORT = qw/add_cron del_cron getcron setcron/;
our @EXPORT_OK = qw/add_cron del_cron getcron setcron fix_line/;

sub add_cron {
    my $file = shift;
    return unless -e $file;

    my @cron = getcron();
    my %existing = map { $_ => 1 } @cron;

    open( my $add, '<', $file ) || die( "Cannot open $file: $!\n" );
    while ( chomp(my $line = <$add>)) {
        # Do not add one multiple times
        push @cron => $line unless $existing{ fix_line( $line )};
    }
    close( $add );

    setcron( @cron );
}

sub del_cron {
    my $file = shift;
    return unless -e $file;

    my @cron_lines = getcron();

    open( my $del, '<', $file ) || die( "Cannot open $file: $!\n" );
    while ( chomp( my $line = <$del> )) {
        @cron_lines = grep { $_ ne fix_line( $line )} @cron_lines;
    }
    close( $del );

    setcron( @cron_lines );
}

sub getcron {
    my $crontext = `crontab -l`;
    my @results;
    @results = split( '\n', $crontext ) unless $?;
    return @results;
}

sub setcron {
    my @lines = @_;

    my ( $name, $number ) = ( "/tmp/rtcron", 1 );
    $number++ while ( -e "$name-$number" );

    open( my $rtcron, ">", "$name-$number" ) || die( "Cannot open file: $!\n" );
    print $rtcron fix_line( join( "\n", @lines )), "\n";
    close( $rtcron );

    system( "crontab '$name-$number'" );
    unlink( "$name-$number" );
}

sub fix_line {
    my ( $line ) = @_;
    my $PATH  = RTDevSys->RTHOME;
    my $DB    = RTDevSys->RT_DB;
    my $USER  = RTDevSys->RT_DB_USER;
    my $GROUP = RTDevSys->RT_GROUP;
    $line =~ s/\%path\%/$PATH/g;
    $line =~ s/\%db\%/$DB/g;
    $line =~ s/\%user\%/$USER/g;
    $line =~ s/\%group\%/$GROUP/g;
    return $line;
}

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

