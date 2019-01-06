#!/usr/bin/perl
use strict;

package Disketo_Utils; 
my $VERSION=0.1;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(go_recursivelly);

# Lists recursivelly all the subdirectories of given directory 
# and for each it calls the given anonymous function
sub go_recursivelly($&) {
	my $dir = shift @_;
	my $visitor = shift @_;
	
	$visitor->($dir);

	opendir(my $dh, $dir) || die "Can't open $dir: $!";

	while (my $child = readdir $dh) {
			if ($child eq "." || $child eq "..") {
				next;
			}
	
			my $subpath = "$dir/$child";
			if (!(-d $subpath)) {
				next;
			}
			if (!(-r $subpath)) {
				print STDERR "Cannot read $subpath!\n";
				next;
			}
		
			##print "$subpath\n";
			go_recursivelly($subpath, $visitor);
	}

	closedir $dh;
}

# Prints the directory tree
sub print_tree($) {
	my $dir = shift @_;

	go_recursivelly($dir, sub {
		my $dir = shift @_;

		my @parts = split(/\//, $dir);
		my $name = pop @parts;
		my $count = scalar @parts;
		print "|   " x $count;
		print "+ $name\n";
	});
}
