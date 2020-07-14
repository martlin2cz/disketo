#!/usr/bin/perl
use strict;

package Disketo_Instructions; 
my $VERSION=2.0.0;

use Data::Dumper;
use File::Basename;
use Disketo_Utils; 
use Disketo_Engine;
 
########################################################################
# The implementing module of the Engine. Implements the particular 
# functions, which may be then mapped to instructions.
########################################################################

########################################################################
# The simple resource -> something functions

sub file_of_file($$) {
	my ($file, $context) = @_;
	return $file;
}

sub dir_of_dir($$) {
	my ($dir, $context) = @_;
	return $dir;
}

sub name_of_file($$) {
	my ($file, $context) = @_;
	return basename($file);
}

sub name_of_dir($$) {
	my ($dir, $context) = @_;
	return basename($dir);
}

sub count_of_children($$) {
	my ($dir, $context) = @_;
	my @children = @{ $context->{"resources"}->{$dir} };
	return scalar @children;
}


sub load_stats_of_file($) {
	#TODO ...
}


########################################################################
# The matchers creating functions

sub meta_matcher($) {
	my ($meta_name) = @_;
	
	my $matcher = sub($$) {
		my ($resource, $context) = @_;
		return $context->{$meta_name}->{$resource};
	};
	
	return $matcher;
}

sub matcher_of_pattern($) {
	my ($pattern) = @_;
	
	my $matcher = sub($$) {
		my ($resource, $context) = @_;
		return $resource =~ /$pattern/;
	};
	
	return $matcher;
}
	
#~ sub matcher_of_files_matching($$) {
	#~ my ($files_matcher, $count) = @_;
	
	#~ my $matcher = sub($$) {
		#~ my ($dir, $context) = @_;
		#~ my @children = @{ $context->{"resources"}->{$dir} };
		#~ for my $child in (@children):
			#~ my $matches
		
	#~ };
	
	#~ return $matcher;
	
sub matcher_of_at_least_files_matching($$) {
	my ($files_matcher, $min_count) = @_;
	
	my $matcher = sub($$) {
		my ($dir, $context) = @_;
		my @children = @{ $context->{"resources"}->{$dir} };
		
		my $count = 0;
		for my $child (@children) {
			if ($files_matcher->($child)) {
				$count++;
			}
		}
		
		return $count > $min_count;
	};
	
	return $matcher;
}


sub duplicities_matcher_by_group($$$) {
	my ($groupper, $group_name, $context) = @_;
	my $matcher = sub($$) {
		my ($resource, $context) = @_;
		my $resource_group_key = $groupper->($resource, $context);
		my @group = @{ $context->{$group_name}->{$resource_group_key} };
		
		return scalar @group > 0;
	};
	
	return $matcher;
}

########################################################################
# Computing and grouping functions

sub _group_files_by_names($) {
	my ($context) = @_;
	Disketo_Engine::group_files(\&Disketo_Instructions::name_of_file, "file names", $context);
}

sub _group_dirs_by_names($) {
	my ($context) = @_;
	Disketo_Engine::group_dirs(\&Disketo_Instructions::name_of_dir, "dir names", $context);
}


sub _compute_files_matching($$) {
	my ($matcher, $context) = @_;
	my $computer = sub($$) {
		my ($file, $context) = @_;
		return $matcher->($file, $context);
	};
	
	Disketo_Engine::calculate_for_each_file($computer, "files matching", $context);
}

sub _compute_dirs_matching($$) {
	my ($matcher, $context) = @_;
	my $computer = sub($$) {
		my ($dir, $context) = @_;
		return $matcher->($dir, $context);
	};
	
	Disketo_Engine::calculate_for_each_dir($computer, "dirs matching", $context);
}


sub _compute_files_of_dir_matching($$) {
	my ($file_matcher, $context) = @_;
	my $computer = sub($$) {
		my ($dir, $context) = @_;
		my @children = @{ $context->{"resources"}->{$dir} };
		my @result = ();
		
		for my $child (@children) {
			my $matches = $file_matcher->($child, $context);
			if ($matches) {
				push @result, $child;
			}
		}
		
		return \@result;
	};
	Disketo_Engine::calculate_for_each_dir($computer, "dirs matching", $context);
}

########################################################################
########################################################################
# The remaining instructions

sub load($$) {
	my ($context, $roots) = @_;
	Disketo_Engine::load($roots, $context);
}

sub context_stats($) {
	my ($context) = @_;
	Disketo_Engine::context_stats($context);
}

########################################################################
# Grouping functions

sub group_files_by_names($) {
	my ($context) = @_;
	Disketo_Engine::group_files(\&Disketo_Instructions::name_of_file, "file names", $context);
}

sub group_dirs_by_names($) {
	my ($context) = @_;
	Disketo_Engine::group_dirs(\&Disketo_Instructions::name_of_dir, "dir names", $context);
}

sub group_files_by_custom($$$) {
	my ($context, $groupper, $name) = @_;
	Disketo_Engine::group_files($groupper, $name, $context);
}

sub group_dirs_by_custom($$$) {
	my ($context, $groupper, $name) = @_;
	Disketo_Engine::group_dirs($groupper, $name, $context);
}

########################################################################
# Computing functions

sub count_files($) {
	my ($context) = @_;
	Disketo_Engine::calculate_for_each_dir(\&Disketo_Instructions::count_of_children, "children count", $context);
}

# TODO compute_dir_size

sub compute_custom_for_each_dir($$$) {
	my ($context, $meta_name, $computer) = @_;
	Disketo_Engine::calculate_for_each_dir($computer, $meta_name, $context);
}

sub compute_custom_for_each_file($$$) {
	my ($context, $meta_name, $computer) = @_;
	Disketo_Engine::calculate_for_each_file($computer, $meta_name, $context);
}

sub load_stats($) {
	my ($context) = @_;
	
	die("TODO load_stats");
	#TODO
}

########################################################################
# Compute matching metas

sub compute_files_matching_pattern($$) {
	my ($context, $pattern) = @_;
	my $matcher = matcher_of_pattern($pattern);
	Disketo_Engine::calculate_for_each_file($matcher, "files matching", $context);
}

sub compute_files_matching_custom($$) {
	my ($context, $matcher) = @_;
	Disketo_Engine::calculate_for_each_file($matcher, "files matching", $context);
}

sub compute_dirs_matching_pattern($$) {
	my ($context, $pattern) = @_;
	my $matcher = matcher_of_pattern($pattern);
	Disketo_Engine::calculate_for_each_dir($matcher, "dirs matching", $context);
}

sub compute_dirs_matching_custom($$) {
	my ($context, $matcher) = @_;
	Disketo_Engine::calculate_for_each_file($matcher, "dirs matching", $context);
}

sub compute_files_of_dir_matching_pattern($$) {
	my ($context, $pattern) = @_;
	my $matcher = matcher_of_pattern($pattern);
	Disketo_Engine::calculate_for_each_file($matcher, "files matching", $context);
}

sub compute_files_of_dir_matching_custom($$) {
	my ($context, $matcher) = @_;
	Disketo_Engine::calculate_for_each_file($matcher, "files matching", $context);
}


########################################################################
# Printing functions

sub print_dirs_simply($) {
	my ($context) = @_;
	Disketo_Engine::print_dirs(\&Disketo_Instructions::dir_of_dir, $context);
}

sub print_dirs_custom($$) {
	my ($context, $printer) = @_;
	Disketo_Engine::print_dirs($printer, $context);
}

sub print_files_simply($) {
	my ($context) = @_;
	Disketo_Engine::print_files(\&Disketo_Instructions::file_of_file, $context);
}

sub print_files_custom($$) {
	my ($context, $printer) = @_;
	Disketo_Engine::print_files($printer, $context);
}

########################################################################
# Simply filtering functions

sub filter_dirs_matching_pattern($$) {
	my ($context, $pattern) = @_;
	my $matcher = matcher_of_pattern($pattern);
	Disketo_Engine::filter_dirs($matcher, $context);
}

sub filter_dirs_matching_custom($$) {
	my ($context, $matcher) = @_;
	Disketo_Engine::filter_dirs($matcher, $context);
}

sub filter_dirs_by_meta($$) {
	my ($context, $meta_name) = @_;
	my $matcher = meta_matcher($meta_name);
	Disketo_Engine::filter_dirs($matcher, $context);
}


sub filter_files_matching_pattern($$) {
	my ($context, $pattern) = @_;
	my $matcher = matcher_of_pattern($pattern);
	Disketo_Engine::filter_files($matcher, $context);	
}

sub filter_files_matching_custom($$) {
	my ($context, $matcher) = @_;
	Disketo_Engine::filter_files($matcher, $context);	
}

sub filter_files_by_meta($$) {
	my ($context, $meta_name) = @_;
	my $matcher = meta_matcher($meta_name);
	Disketo_Engine::filter_files($matcher, $context);
}


sub filter_dirs_with_files_matching_pattern($$$) {
	my ($context, $files_pattern, $count) = @_;
	my $files_matcher = matcher_of_pattern($files_pattern);
	my $matcher = matcher_of_at_least_files_matching($files_matcher, $count);
	Disketo_Engine::filter_dirs($matcher, $context);
}

sub filter_dirs_with_files_matching_custom($$$) {
	my ($context, $files_matcher, $count) = @_;
	my $matcher = matcher_of_at_least_files_matching($files_matcher, $count);
	Disketo_Engine::filter_dirs($matcher, $context);
}

sub filter_dirs_with_files_matching_meta($$$) {
	my ($context, $meta_name, $count) = @_;
	my $files_matcher = meta_matcher($meta_name);
	my $matcher = matcher_of_at_least_files_matching($files_matcher, $count);
	Disketo_Engine::filter_dirs($matcher, $context);
}


########################################################################
# Duplicities filtering functions

sub filter_duplicate_files_by_custom_groupper($$$) {
	my ($context, $meta_name, $groupper) = @_;
	my $matcher = duplicities_matcher_by_group($groupper, $meta_name, $context);
	Disketo_Engine::filter_files($matcher, $context);	
}

sub filter_duplicate_files_by_name($) {
	my ($context) = @_;
	my $matcher = duplicities_matcher_by_group(\&Disketo_Instructions::name_of_file, "file names", $context);
	Disketo_Engine::filter_files($matcher, $context);	
}


sub filter_duplicate_dirs_by_custom_groupper($$$) {
	my ($context, $meta_name, $groupper) = @_;
	my $matcher = duplicities_matcher_by_group($groupper, $meta_name, $context);
	Disketo_Engine::filter_dirs($matcher, $context);	
}

sub filter_duplicate_dirs_by_name($) {
	my ($context) = @_;
	my $matcher = duplicities_matcher_by_group(\&Disketo_Instructions::name_of_dir, "dir names", $context);
	Disketo_Engine::filter_dirs($matcher, $context);
}

sub filter_duplicate_dirs_with_common_files_by_name($$) {
	my ($context, $count) = @_;
	my $files_matcher = duplicities_matcher_by_group(\&Disketo_Instructions::name_of_file, "dirs matching", $context);
	my $matcher = matcher_of_at_least_files_matching($files_matcher, $count);
	Disketo_Engine::filter_dirs($matcher, $context);
}

sub filter_duplicate_dirs_with_common_files_by_custom_groupper($$$) {
	my ($context, $groupper, $count) = @_;
	my $files_matcher = duplicities_matcher_by_group($groupper, "dirs matching", $context);
	my $matcher = matcher_of_at_least_files_matching($files_matcher, $count);
	Disketo_Engine::filter_dirs($matcher, $context);
}

########################################################################
# Filter duplicities by comparer

sub filter_duplicate_dirs_by_custom_comparer($$) {
	my ($context, $comparer) = @_;
	
	#TODO
	die("TODO: filter_duplicate_dirs_by_custom_comparer");
}

sub filter_duplicate_files_by_custom_comparer($$) {
	my ($context, $comparer) = @_;
	
	#TODO
	die("TODO: filter_duplicate_files_by_custom_comparer");
}

sub filter_duplicate_dirs_with_common_files_by_custom_comparer($$) {
	my ($context, $files_comparer) = @_;
	
	#TODO
	die("TODO: filter_duplicate_dirs_with_common_files_by_custom_comparer");
}
