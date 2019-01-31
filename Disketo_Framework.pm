#!/usr/bin/perl
use strict;

package Disketo_Framework; 
my $VERSION=0.1;

use File::Basename;
use File::stat;
use Data::Dumper;
use Disketo_Utils; 


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
		%stats = (%stats, %stat);
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

#############################################################
# Filters given reference to hash of directories
# against the given pattern
sub filter_directories_by_pattern($$) {
	my $dirs_ref = shift @_;
	my $pattern = shift @_;

	my $predicate = sub {
		my $dir = shift @_;
		return $dir =~ /$pattern/;
	};
	
	return filter_directories($dirs_ref, $predicate);
}


#############################################################
# Filters given reference to hash of directories
# by matching at least given number of child resources
# against the given filename pattern
sub filter_directories_by_files_pattern($$$) {
	my $dirs_ref = shift @_;
	my $pattern = shift @_;
	my $threshold = shift @_;

	my $predicate = sub {
		my $dir = shift @_;
		my @children = @{ shift @_ };
		
		my @matching = grep(/$pattern/, @children);
		return scalar @matching >= $threshold;
	};
	
	return filter_directories($dirs_ref, $predicate);
}

##############################################################
#############################################################
# CROSS AND MORE COMPLEX FILTERING
#############################################################
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
# leaving only the directories of the same name
sub filter_directories_of_same_name($) {
	my $dirs_ref = shift @_;
	
	my $matcher = sub {
		my $left_dir = shift @_;
		my @left_children = @{ shift @_ };
		my $right_dir = shift @_;
		my @right_children = @{ shift @_ };

		my $left_name = basename($left_dir);
		my $right_name = basename($right_dir);

		return $left_name eq $right_name;
	};

	return filter_directories_matching($dirs_ref, $matcher);	
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

#############################################################
# Filters given reference to hash of directories
# leaving only the directories with at least given number
# of common files of the same name
sub filter_directories_with_common_file_names($$) {
	my $dirs_ref = shift @_;
	my $min_count = shift @_;

	my $files_matcher = sub {
		my $left = shift @_;
		my $right = shift @_;

		my $left_name = basename($left);
		my $right_name = basename($right);

		return $left_name eq $right_name;
	};

	return filter_directories_with_common_files($dirs_ref, $min_count, $files_matcher);	
}

#############################################################
# Filters given reference to hash of directories
# with given stats
# leaving only the directories with at least given number
# of common files of the same name and size
sub filter_directories_with_common_file_names_with_size($$$) {
	my $dirs_ref = shift @_;
	my $stats_ref = shift @_;
	my $min_count = shift @_;

	my %stats = %{ $stats_ref };

	my $files_matcher = sub {
		my $left = shift @_;
		my $right = shift @_;

		my $left_name = basename($left);
		my $right_name = basename($right);
		
		my $same_name = ($left_name eq $right_name);
		if (!$same_name) {
			return 0;
		}
		
		my $left_size = %stats{$left}->size;
		my $right_size = %stats{$right}->size;

		my $same_size = ($left_size == $right_size);
		return $same_size;
	};

	return filter_directories_with_common_files($dirs_ref, $min_count, $files_matcher);	
}


##############################################################
#############################################################
# PRINTING
#############################################################
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

#############################################################
# Prints given reference to hash of directories
# simply as a list
sub print_directories_simply($) {
	my $dirs_ref = shift @_;
	
	my $printer = sub {
		my $dir = shift @_;
		return $dir;
	};

	print_directories($dirs_ref, $printer);
}



## TODO here
