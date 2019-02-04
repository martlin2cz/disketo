#!/usr/bin/perl
use strict;

package Disketo_Extras; 
my $VERSION=0.1;

use File::Basename;
use Data::Dumper;

use Disketo_Core; 
use Disketo_Utils; 


#############################################################
# LIST DIRECTORIES
#############################################################
# Lists all directories recursivelly of given list of root directories
sub list_all_directories(@) {
	my @roots = @_;

	Disketo_Utils::log_entry("Listing all directories in " . join(", ", @roots));

	my %result = ();
	for my $root (@roots) {
		my %sub_result = %{ Disketo_Core::list_directory($root) };
		%result = (%result, %sub_result);
	}

	Disketo_Utils::log_exit("Got " . (scalar keys %result) . " of them");

	return \%result;
}

#############################################################
# For given input dirs ref loads their stats
# Returns both (ref to %dirs and ref to %stats)
sub load_stats($) {
	my $dirs_ref = shift @_;

	Disketo_Utils::log_entry("Loading stats of directories");
	my ($filtered_ref, $stats_ref) = Disketo_Core::load_stats($dirs_ref);
	
	Disketo_Utils::log_exit("Got " . (scalar keys %{ $stats_ref }) . " of them");
	return ($filtered_ref, $stats_ref);
}

##############################################################
#############################################################
# SIMPLE, LINEAR FILTERING
#############################################################
# Filters given reference to hash of directories
# against the given predicate
sub filter_directories_custom($$) {
	my $dirs_ref = shift @_ ;
	my $predicate = shift @_;

	Disketo_Utils::log_entry("Filtering directories against predicate");
	my $filtered_ref = Disketo_Core::filter_directories($dirs_ref, $predicate);
	
	Disketo_Utils::log_exit("Got " . (scalar keys %{ $filtered_ref }) . " of them");
	return $filtered_ref;
}

#############################################################
# Filters given reference to hash of directories
# against the given pattern
sub filter_directories_by_pattern($$) {
	my $dirs_ref = shift @_;
	my $pattern = shift @_;

	Disketo_Utils::log_entry("Filtering directories matching $pattern");

	my $predicate = sub {
		my $dir = shift @_;
		return $dir =~ /$pattern/;
	};
	
	my $filtered_ref = Disketo_Core::filter_directories($dirs_ref, $predicate);

	Disketo_Utils::log_exit("Got " . (scalar keys %{ $filtered_ref }) . " of them");
	return $filtered_ref;
}


#############################################################
# Filters given reference to hash of directories
# by matching at least given number of child resources
# against the given filename pattern
sub filter_directories_by_files_pattern($$$) {
	my $dirs_ref = shift @_;
	my $pattern = shift @_;
	my $threshold = shift @_;

	Disketo_Utils::log_entry("Filtering directories matching files pattern $pattern w/ at least $threshold");

	my $predicate = sub {
		my $dir = shift @_;
		my @children = @{ shift @_ };
		
		my @matching = grep(/$pattern/, @children);
		return scalar @matching >= $threshold;
	};
	
	my $filtered_ref = Disketo_Core::filter_directories($dirs_ref, $predicate);

	Disketo_Utils::log_exit("Got " . (scalar keys %{ $filtered_ref }) . " of them");
	return $filtered_ref;
}

##############################################################
#############################################################
# CROSS AND MORE COMPLEX FILTERING
#############################################################
# Filters given reference to hash of directories
# matched each-to-each by given matcher function
# returning filtered dirs and hash of matching pairs
sub filter_directories_matching($$) {
	my $dirs_ref = shift @_;
	my $matcher = shift @_;

	Disketo_Utils::log_entry("Filtering directories matching predicate");
	my ($filtered_ref, $pairs_ref) = Disketo_Core::filter_directories_matching($dirs_ref, $matcher);

	Disketo_Utils::log_exit("Got " . (scalar keys %{ $filtered_ref }) . " of them");
	return ($filtered_ref, $pairs_ref);
}

#############################################################
# Filters given reference to hash of directories
# leaving only the directories of the same name
sub filter_directories_of_same_name($) {
	my $dirs_ref = shift @_;
	
	Disketo_Utils::log_entry("Filtering directories of same name");

	my $matcher = sub {
		my $left_dir = shift @_;
		my @left_children = @{ shift @_ };
		my $right_dir = shift @_;
		my @right_children = @{ shift @_ };

		my $left_name = basename($left_dir);
		my $right_name = basename($right_dir);

		return $left_name eq $right_name;
	};

	my ($filtered_ref, $pairs_ref) = Disketo_Core::filter_directories_matching($dirs_ref, $matcher);

	Disketo_Utils::log_exit("Got " . (scalar keys %{ $filtered_ref }) . " of them");
	return ($filtered_ref, $pairs_ref);
}


#############################################################
# Filters given reference to hash of directories
# having at least given number of common children
# by matching by given matcher function
sub filter_directories_with_common_files($$$) {
	my $dirs_ref = shift @_;
	my $min_count = shift @_;
	my $files_matcher = shift @_;
	
	Disketo_Utils::log_entry("Filtering directories with at least $min_count common files");

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

	my ($filtered_ref, $pairs_ref) = Disketo_Core::filter_directories_matching($dirs_ref, $dirs_matcher);

	Disketo_Utils::log_exit("Got " . (scalar keys %{ $filtered_ref }) . " of them");
	return ($filtered_ref, \%intersects);
}

#############################################################
# Filters given reference to hash of directories
# leaving only the directories with at least given number
# of common files of the same name
sub filter_directories_with_common_file_names($$) {
	my $dirs_ref = shift @_;
	my $min_count = shift @_;

	Disketo_Utils::log_entry("Filtering directories with at least $min_count common file names");

	my $files_matcher = sub {
		my $left = shift @_;
		my $right = shift @_;

		my $left_name = basename($left);
		my $right_name = basename($right);

		return $left_name eq $right_name;
	};

	my ($filtered_ref, $intersects_ref) = filter_directories_with_common_files($dirs_ref, $min_count, $files_matcher);	
	Disketo_Utils::log_exit("Got " . (scalar keys %{ $filtered_ref }) . " of them");
  return ($filtered_ref, $intersects_ref);
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

	Disketo_Utils::log_entry("Filtering directories with at least $min_count common files (name+size)");

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

	my ($filtered_ref, $intersects_ref) = filter_directories_with_common_files($dirs_ref, $min_count, $files_matcher);	
	
	Disketo_Utils::log_exit("Got " . (scalar keys %{ $filtered_ref }) . " of them");
  return ($filtered_ref, $intersects_ref);
}


##############################################################
#############################################################
# PRINTING
#############################################################
# Prints given reference to hash of directories
# simply as a list
sub print_directories_simply($) {
	my $dirs_ref = shift @_;

	Disketo_Utils::log_entry("Printing directories simply");

	my $printer = sub {
		my $dir = shift @_;
		return $dir;
	};

	Disketo_Core::print_directories($dirs_ref, $printer);

	Disketo_Utils::log_exit("Printed " . (scalar keys %{ $dirs_ref }) . " of them");
}


############################################################
# Prints given reference to hash of directories
# by given printer function
sub print_directories($$) {
	my $dirs_ref = shift @_;
	my $printer = shift @_;

	Disketo_Utils::log_entry("Printing directories by printer");

	Disketo_Core::print_directories($dirs_ref, $printer);

	Disketo_Utils::log_exit("Printed " . (scalar keys %{ $dirs_ref }) . " of them");
}

############################################################
# Prints given reference to hash of directories
# listing their files
sub print_files($$) {
	my $dirs_ref = shift @_;
	my $printer = shift @_;

	Disketo_Utils::log_entry("Printing files by printer");

	Disketo_Core::print_files($dirs_ref, $printer);

	Disketo_Utils::log_exit("Printed " . (scalar keys %{ $dirs_ref }) . " of them");
}
	
