#!/usr/bin/perl
use strict;

package Disketo_Framework; 
my $VERSION=0.1;

use DateTime;
use File::stat;
use Data::Dumper;

##############################################################
#############################################################
# LIST DIRECTORIES
#############################################################
# Lists all directories recursivelly of given list of root directories
sub list_all_directories(@) {
	my @roots = @_;

	my %result = ();
	for my $root (@roots) {
		my %sub_result = list_directory($root);
		%result = (%result, %sub_result);
	}

	return %result;
}


#############################################################
# Lists recursivelly all the subdirectories of given directory 
# returns hash mapping for each path the directory children
sub list_directory($) {
	my ($dir) = @_;
	my %result = ();

	my @children = children_of($dir);
	
	$result{$dir} = \@children;

	foreach my $child (@children) {
		if (-d $child) {
			my %sub_result = list_directory($child);
			%result = (%result, %sub_result);
		}
	}

	return %result;		
}	

#############################################################
# Returns array containing all (non-hidden) child resources in given directory
# Note: internal function
sub children_of($) {
	my ($dir) = @_;

	my @result = ();

	my $dh;
	unless (opendir($dh, $dir)) {
		print STDERR "Can't open $dir: $!\n";
		return @result;
	}

	while (my $child = readdir $dh) {
			if (substr($child, 0, 1) eq ".") {
				next;
			}
			
			my $subpath = "$dir/$child";
			push @result, $subpath;
	}

	closedir $dh;

	return @result;
}

##############################################################
#############################################################
# PROCESS DIRECTORIES
#############################################################

## TODO

