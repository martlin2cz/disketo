#!/usr/bin/perl                                                                                                                        

use strict;
BEGIN { unshift @INC, "."; }

use Disketo_Utils;
#######################################
my @dirs = @ARGV;
print_tree(@dirs);
#######################################

# Prints the directory tree
sub print_tree($) {
	my $dir = shift @_;

	Disketo_Utils::go_recursivelly($dir, sub {
		my $dir = shift @_;

		my @parts = split(/\//, $dir);
		my $name = pop @parts;
		my $count = scalar @parts;
		print "|   " x $count;
		print "+ $name\n";

		return 1;
	});
}
