#!/usr/bin/perl
# https://perldoc.perl.org/functions/readdir.html
use strict;

my $some_dir = shift @ARGV || die "Please specify dir to list!";


opendir(my $dh, $some_dir) || die "Can't open $some_dir: $!";

while (readdir $dh) {
	print "$some_dir $_\n";
}

closedir $dh;
