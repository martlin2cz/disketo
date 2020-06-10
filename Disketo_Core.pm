#!/usr/bin/perl
use strict;

package Disketo_Core; 
my $VERSION=0.2;

use File::Basename;
use File::stat;
use Data::Dumper;
use Disketo_Utils; 

#############################################################
# Lists either the all the directories if the $ is directory,
# or simply loads the listed resources from the $ text file.
# Fails otherwise.
sub list($) {
	my ($dir_or_file) = @_;

	if (-d $dir_or_file) {
		return list_directory($dir_or_file);
	}
	if (-f $dir_or_file) {
		return list_from_file($dir_or_file);
	}

	die("Nor directory or file: $dir_or_file ")	
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
# Lists all the paths from the given file. Assuming absolute paths
# and one at each line.
sub list_from_file($) {
	my ($file) = @_;
	
	my $lines_ref = load_lines($file);
	return files_to_dirs($lines_ref);
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
# For given input file loads all its lines
sub load_lines($) {
	my ($file) = @_;

	my $handle;
	unless(open $handle, '<', $file) {
		print STDERR "Can't open $file: $!\n";
		return \{}
	}
	chomp(my @lines = <$handle>);
	close $handle;

	return \@lines;
}

#############################################################
# For given input lines (representing the files paths) list ref
# creates ref to hash with their dirs.
sub files_to_dirs($) {
	my @files = @{ shift @_ };
	my %result = ();

	for my $file (@files) {
		my @parts = split(/\/+/, $file);
		pop @parts;
		my $parent = join("/", @parts);
		
		push @{ $result{$parent} }, $file;
	}

	return \%result;
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
		%stats = (%stats, %stat);
	}

	return (\%dirs, \%stats);
}

#############################################################
# Filters given reference to hash of directories
# against the given predicate
sub filter_directories($$) {
	my %dirs = %{ shift @_ };
	
	my $predicate = shift @_;

	my %result = ();
	for my $dir (keys %dirs) {
		my @children = @{%dirs{$dir}};

		my $okay = $predicate->($dir, \@children);
		if ($okay) {
			$result{$dir} = \@children;
		}
	}

	return \%result;
}


############################################################
# Filters given reference to hash of directories
# matched each-to-each by given matcher function
# returning filtered dirs and hash of matching pairs
sub filter_directories_matching($$) {
	my %dirs = %{ shift @_ };
	my $matcher = shift @_;

	my %filtered = ();
	my %pairs = ();
	for my $left_dir (keys %dirs) {
		my $left_children_ref = %dirs{$left_dir};

		for my $right_dir (keys %dirs) {
			if ($left_dir eq $right_dir) {
				next;
			}

			my $right_children_ref = %dirs{$right_dir};
			
			my $match = $matcher->($left_dir, $left_children_ref, $right_dir, $right_children_ref);
			if ($match) {
				$filtered{$left_dir} = $left_children_ref;
				push (@{ $pairs{$left_dir} }, $right_dir);
			}
		}
	}

	return (\%filtered, \%pairs);
}

#############################################################
# Filters given reference to hash of directories
# having at least given number of common children
# by matching by given matcher function
sub filter_directories_with_common_files($$$) {
	my $dirs_ref = shift @_;
	my $min_count = shift @_;
	my $files_matcher = shift @_;
	
	my %intersects = ();

	my $dirs_matcher = sub {
		my $left_dir = shift @_;
		my $left_children_ref = shift @_;
		my $right_dir = shift @_;
		my $right_children_ref = shift @_;

		my $intersect_ref = Disketo_Utils::intersect($left_children_ref, $right_children_ref, $files_matcher);
		if (scalar keys %{ $intersect_ref } >= $min_count) {
			$intersects{$left_dir}{$right_dir} = $intersect_ref;
			return 1;
		} else {
			return 0;
		}
	};

	my ($filtered_ref, $pairs_ref) = filter_directories_matching($dirs_ref, $dirs_matcher);	
	return ($filtered_ref, \%intersects);
}


############################################################
# Prints given reference to hash of directories
# by given printer function
sub print_directories($$) {
	my %dirs = %{ shift @_ };
	my $printer = shift @_;

	my @dirs = keys %dirs;
	@dirs = sort @dirs;

	for my $dir (@dirs) {
		my $printed = $printer->($dir);
		print "$printed\n";
	}
}

############################################################
# Prints given reference to hash of directories
# by given printer function
sub print_files($$) {
	my %dirs = %{ shift @_ };
	my $printer = shift @_;

	my @files = ();
	for my $dir (keys %dirs) {
		my @subfiles = @{ %dirs{$dir} };
		@files = (@files, @subfiles);
	}

	@files = sort @files;

	for my $file (@files) {
		my $printed = $printer->($file);
		print "$printed\n";
	}
}

