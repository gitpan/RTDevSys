#!/usr/bin/perl
use strict;
use warnings;

my $files;
BEGIN {
    chomp( $files = `find lib -name '*.pm'` );
    $files = [ split( "\n", $files )];
}

use Test::Pod tests => my $count = @$files;

for my $file ( @$files ) {
    pod_file_ok( $file, "checking POD for $file." )
}
