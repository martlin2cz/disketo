#!/usr/bin/perl
use strict;

package Disketo_Framework; 
my $VERSION=0.1;

use File::Basename;
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
		my %sub_result = %{ list_directory($root) };
		%result = (%result, %sub_result);
	}

	return \%result;
}


#############################################################
# Lists recursivelly all the subdirectories of given directory 
# returns ref to hash mapping for each path the directory children
sub list_directory($) {
	my ($dir) = @_;
	my %result = ();

	my $children_ref = children_of($dir);
	my @children = @{ $children_ref };
	$result{$dir} = $children_ref;

	foreach my $child (@children) {
		if (-d $child) {
			my %sub_result = %{ list_directory($child) };
			%result = (%result, %sub_result);
		}
	}

	return \%result;		
}	

#############################################################
# Returns ref to array containing all (non-hidden) child resources 
# in given directory
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

	return \@result;
}

#############################################################
# For given input dirs ref loads their stats
# Returns both (ref to %dirs and ref to %stats)
sub load_stats($) {
	my %dirs = %{ shift @_ };

	my %stats = ();
	for my $dir (keys %dirs) {
		my @children = @{%dirs{$dir}};
		my %stat = map { $_ => stat($_) } @children;
		$stats{$dir} = \%stat;
	}

	return (\%dirs, \%stats);
}

##############################################################
#############################################################
# SIMPLE, LINEAR FILTERING
#############################################################
# Filters given reference to hash of directories
# against the given predicate
sub filter_directories($$) {
	my %dirs = %{shift @_};
	
	my $predicate = shift @_;

	my %result = ();
	for my $dir (keys %dirs) {
		my @children = @{%dirs{$dir}};

		my $okay = $predicate->($dir, \@children);
		if ($okay) {
			$result{$dir} = \@children;
		}
	}

	return %result;
}

#############################################################
# Filters given reference to hash of directories
# against the given pattern
sub filter_directories_by_pattern($$) {
	my %dirs = %{shift @_};
	my $pattern = shift @_;

	my $predicate = sub {
		my $dir = shift @_;
		return $dir =~ /$pattern/;
	};
	
	return filter_directories(\%dirs, $predicate);
}


#############################################################
# Filters given reference to hash of directories
# by matching at least given number of child resources
# against the given filename pattern
sub filter_directories_by_files_pattern($$$) {
	my %dirs = %{shift @_};
	my $pattern = shift @_;
	my $threshold = shift @_;

	my $predicate = sub {
		my $dir = shift @_;
		my @children = @{ shift @_ };
		
		my @matching = grep(/$pattern/, @children);
		return scalar @matching >= $threshold;
	};
	
	return filter_directories(\%dirs, $predicate);
}

##############################################################
#############################################################
# CROSS AND MORE COMPLEX FILTERING
#############################################################
# Filters given reference to hash of directories
# matched each-to-each by given matcher function
sub filter_directories_matching($$) {
	my %dirs = %{shift @_};
	my $matcher = shift @_;

	my %result = ();
	for my $left_dir (keys %dirs) {
		my @left_children = @{ %dirs{$left_dir} };

		for my $right_dir (keys %dirs) {
			if ($left_dir eq $right_dir) {
				next;
			}

			my @right_children = @{ %dirs{$right_dir} };
			
			my $match = $matcher->($left_dir, \@left_children, $right_dir, \@right_children);
			if ($match) {
				$result{$left_dir} = \@left_children;
			}
		}
	}

	return %result;
}

#############################################################
# Filters given reference to hash of directories
# leaving only the directories of the same name
sub filter_directories_of_same_name($) {
	my %dirs = %{shift @_};
	
	my $matcher = sub {
		my $left_dir = shift @_;
		my @left_children = @{ shift @_ };
		my $right_dir = shift @_;
		my @right_children = @{ shift @_ };

		my $left_name = basename($left_dir);
		my $right_name = basename($right_dir);

		return $left_name eq $right_name;
	};

	return filter_directories_matching(\%dirs, $matcher);	
}


## TODO here
