#!/usr/bin/perl
use strict;

package Disketo_Instructions; 
my $VERSION=3.0.0;

use Data::Dumper;
use File::Basename;
use Disketo_Utils; 
use Disketo_IO;
 
########################################################################
# The implementing module of the Engine. Implements the particular 
# functions, which may be then mapped to instructions.
# Each of the function returns the sub, but what particular sub it is
# (printer, filter, matcher, computer, actual method, ...) is up to 
# their parent node (caller), unfortunatelly.
########################################################################
# PARAMETERS

# The separator of the printed values (if more on one line).
my $SEPARATOR = "	"; #tabulator

########################################################################
# UTILS

# Returns the value of the given node.
# Do not use directly, call value(node, index) instead.
sub value_of_node($) {
	my ($value_node) = @_;
	if (not exists($value_node->{"value"})) {
		die("Not a value node! " . Dumper($value_node));
	}
	
	my $value = $value_node->{"prepared_value"} ;
	if (not defined($value)) {
		die("Nah, foolish me! Forgot to specify the value!");
	}
	
	return $value;
}

# Returns the child (argument) node of the given index.
sub child_of_node($$) {
	my ($operation_node, $index) = @_;
	
	my $children = $operation_node->{"arguments"};
	return $children->[$index];
}

# Calls the "method" on the given node with that node.
# Do call directly, use the delegate(node, index) instead.
sub delegate_to_node($) {
	my ($to_node) = @_;
	
	my $to_operation = $to_node->{"operation"};
	if (not $to_operation) {
		die("Not an operation node!");
	}
	
	my $to_method = $to_operation->{"method"};
	$to_method->($to_node);
}

########################################################################

# Returns the value of the child_index-th argument of the given node.
sub value($$) {
	my ($node, $child_index) = @_;
	my $child = child_of_node($node, $child_index);
	return value_of_node($child);
}

# Call the "method" of the child_index-th argument of the given node.
sub delegate($$) {
	my ($node, $child_index) = @_;
	my $child = child_of_node($node, $child_index);
	return delegate_to_node($child);
}

# Returns 1 if the given child_index-th argument node is operation of
# the given operation_name.
sub is($$$) {
	my ($node, $child_index, $opname) = @_;
	my $child = child_of_node($node, $child_index);
	return $child->{"name"} eq $opname;
}

########################################################################
########################################################################
# LOADS

sub load($) {
	my ($load_node) = @_;
	my $roots = value($load_node, 0);
	
	return sub($) {
		my ($context) = @_;
		Disketo_Engine::load($roots, $context);
	}
}

########################################################################
# FILTERS

sub filter($) {
	my ($filter_node) = @_;
	return delegate($filter_node, 0);
}

sub filter_files($) {
	my ($filter_files_node) = @_;

	my $predicate = delegate($filter_files_node, 0);
	return sub($) {
		my ($context) = @_;
		Disketo_Engine::filter_files($predicate, $context);
	};
}

sub filter_dirs($) {
	my ($filter_dirs_node) = @_;

	my $predicate = delegate($filter_dirs_node, 0);
	return sub($) {
		my ($context) = @_;
		Disketo_Engine::filter_dirs($predicate, $context);
	};
}

sub matching_pattern($) {
	my ($matching_pattern_node) = @_;

	my $pattern = value($matching_pattern_node, 0);
	
	if (is($matching_pattern_node, 1, "case-sensitive")) {
		return sub($) {
			my ($resource, $context) = @_;
			return ($resource =~ /$pattern/);
		};
	}
	
	if (is($matching_pattern_node, 1, "case-insensitive")) {
		return sub($) {
			my ($resource, $context) = @_;
			return ($resource =~ /$pattern/i);
		};
	}
	
	die("Unsupported.");
}

sub matching_custom_matcher($) {
	my ($matching_custom_matcher_node) = @_;

	my $predicate = value($matching_custom_matcher_node, 0);
	
	return sub($$) {
		my ($resource, $context) = @_;
		return $predicate->($resource, $context);
	};
}

sub having_extension($) {
	my ($having_extension_node) = @_;

	my $extension = value($having_extension_node, 0);
	
	return sub($$) {
		my ($file, $context) = @_;
		
		return ends_with($file, "." . $extension);
	};
}

sub having_files($) {
	my ($having_files_node) = @_;
	
	my $amount = delegate($having_files_node, 0);
	my $condition = delegate($having_files_node, 1);
	
	return sub($$) {
		my ($dir, $context) = @_;
		my $files_matching = files_of_dir_matching($dir, $condition, $context);
		return $amount->($files_matching, $context)
	};
}


sub more_than($) {
	my ($more_than_node) = @_;
	my $count = value($more_than_node, 0);
	
	return sub($$) {
		my ($files, $context) = @_;
		return (scalar @$files) > $count;
	};
}

sub having_group($) {
	my ($having_group_node) = @_;

	my $amount = delegate($having_group_node, 0);
	my $groupper = delegate($having_group_node, 1);

	return sub($$) {
		my ($resource, $context) = @_;
		my $resource_group_key = $groupper->($resource, $context);
		my $resources = $context->{Disketo_Instruction_Set::FG_FILES_GROUPS()}->{$resource_group_key};
		return $amount->($resources, $context);
	};
}

sub with_same_name($) {
	return resource_to_name();
}

sub with_same_name_and_size($) {
	return resource_to_name_and_size();
}

sub with_same_of_custom_group($) {
	my ($with_same_of_custom_group_node) = @_;
	return value($with_same_of_custom_group_node, 0);
}

########################################################################
# EXECUTE
sub execute($) {
	my ($execute_node) = @_;
	
	my $operation = value($execute_node, 0);
	return sub($) {
		my ($context) = @_;
		
		$operation->($context);
	}
}

########################################################################
# COMPUTES

sub compute($) {
	my ($compute_node) = @_;
	return delegate($compute_node, 0);
}

sub compute_for_each_file($) {
	my ($compute_for_each_file_node) = @_;

###	return delegate($compute_for_each_file_node, 0);

	my $info = delegate($compute_for_each_file_node, 0);
	my $function = $info->{"function"};
	my $meta_name = $info->{"meta_name"};
	
	return sub($) {
		my ($context) = @_;
		Disketo_Engine::calculate_for_each_file($function, $meta_name, $context);
	};
}

sub compute_for_each_dir($) {
	my ($compute_for_each_dir_node) = @_;
###	return delegate($compute_for_each_dir_node, 0);
	
	my $info = delegate($compute_for_each_dir_node, 0);
	my $function = $info->{"function"};
	my $meta_name = $info->{"meta_name"};
	
	return sub($) {
		my ($context) = @_;
		Disketo_Engine::calculate_for_each_dir($function, $meta_name, $context);
	};
}


sub count_files($) {
	my ($count_files_node) = @_;
	
	my $function = sub($$) {
		my ($dir, $context) = @_;
		my @children = @{ $context->{"resources"}->{$dir} };
		return scalar @children;
	};
	
	return {"function" => $function, "meta_name" => Disketo_Instruction_Set::FM_CHILDREN_COUNTS()};
}

sub files_stats($) {
	my ($files_stats_node) = @_;
	
	my $function = sub($$) {
		my ($file, $context) = @_;
		
		return Disketo_IO::load_stats_for_file($file);
	};
	
	return {"function" => $function, "meta_name" => Disketo_Instruction_Set::FM_FILE_STATS()};
}


sub compute_custom($) {
	my ($compute_custom_node) = @_;
	
	my $meta_name = value($compute_custom_node, 0);
	my $computer = value($compute_custom_node, 1);
	
	my $function = sub($$) {
		my ($resource, $context) = @_;
		return $computer->($resource, $context);
	};
	
	return {"function" => $function, "meta_name" => $meta_name};
}

########################################################################
# GROUP

sub group($) {
	my ($group_node) = @_;
	return delegate($group_node, 0);
}

sub group_files($) {
	my ($group_files_node) = @_;

	my $groupper = delegate($group_files_node, 0);
	my $group_name = Disketo_Instruction_Set::FG_FILES_GROUPS();
	
	return sub($) {
		my ($context) = @_;
		Disketo_Engine::group_files($groupper, $group_name, $context);
	};
}

sub group_dirs($) {
	my ($group_dirs_node) = @_;

	my $grouper = delegate($group_dirs_node, 0);
	my $group_name = Disketo_Instruction_Set::FG_DIRS_GROUPS();
	
	return sub($) {
		my ($context) = @_;
		Disketo_Engine::group_dirs($grouper, $group_name, $context);
	};
}


sub group_by_name($) {
	my ($group_by_name_node) = @_;
	return resource_to_name();
}

sub group_by_name_and_size($) {
	my ($group_by_name_and_size_node) = @_;
	return resource_to_resource_and_size();
}

sub group_by_custom($) {
	my ($group_by_custom_node) = @_;

	my $groupper = value($group_by_custom_node, 0);
	return sub($$) {
		my ($resource, $context) = @_;
		return $groupper->($resource, $context);
	};
}



########################################################################
# PRINTS

sub print($) {
	my ($print_node) = @_;
	return delegate($print_node, 0);
}

sub print_files($) {
	my ($print_files_node) = @_;

	my $printer = delegate($print_files_node, 0);
	return sub($) {
		my ($context) = @_;
		Disketo_Engine::print_files($printer, $context);
	};
}

sub print_dirs($) {
	my ($print_dirs_node) = @_;

	my $printer = delegate($print_dirs_node, 0);
	return sub($) {
		my ($context) = @_;
		Disketo_Engine::print_dirs($printer, $context);
	};
}

sub print_stats($) {
	my ($print_stats_node) = @_;

	return sub($) {
		my ($context) = @_;
		Disketo_Engine::context_stats($context);
	};
}

sub print_simply($) {
	my ($print_simply_node) = @_;

	return sub($$) {
		my ($resource, $context) = @_;
		return $resource;
	};
}

sub print_only_name($) {
	my ($print_only_name_node) = @_;
	return resource_to_name();
}

sub print_with_counts($) {
	my ($print_with_counts_node) = @_;

	return sub($$) {
		my ($resource, $context) = @_;
		my $count = $context->{Disketo_Instruction_Set::FM_CHILDREN_COUNTS()}->{$resource};
		return "$resource$SEPARATOR$count";
	};
}

sub print_with_size($) {
	my ($print_with_size_node) = @_;
	
	my $size_printer = delegate($print_with_size_node, 0);
	
	return sub($$) {
		my ($file, $context) = @_;
		my $stats = $context->{Disketo_Instruction_Set::FM_FILE_STATS()}->{$file};
		my $size = $stats->{"size"};

		my $size_to_print = $size_printer->($size, $file, $context);
		return "$file$SEPARATOR$size_to_print";
	};
}

sub print_size_in_bytes($) {
	my ($print_size_in_bytes_node) = @_;

	return sub($$$) {
		my ($size, $resource, $context) = @_;
		return "$size B";	
	}
}


sub print_size_human_readable($) {
	my ($print_size_in_bytes_node) = @_;

	return sub($$$) {
		my ($size, $resource, $context) = @_;
		return Disketo_IO::size_to_human_readable($size);	
	}
		
}

sub print_custom($) {
	my ($print_custom_node) = @_;

	my $printer = value($print_custom_node, 0);
	return sub($$) {
		my ($resource, $context) = @_;
		return $printer->($resource, $context);
	};
}
	


########################################################################

#TODO all the remaining ...


########################################################################
# commons

sub resource_to_name() {
	return sub ($$) {
		my ($resource, $context) = @_;
		return basename($resource);
	};
}

sub resource_to_resource_and_size() {
	return sub ($$) {
		my ($resource, $context) = @_;
		my $stats = $context->{Disketo_Instruction_Set::FM_FILE_STATS()}->{$resource};
		my $size = $stats->{"size"};
		return "$resource$SEPARATOR$size";
	};
}


########################################################################
# utils

# Returns 1 if given text ends with given suffix. 
sub ends_with($$) {
	my ($text, $suffix) = @_;

	return ($suffix eq substr($text, -length($suffix)));
}

# Returns the files of the given dir in the given context, 
# which matches the given condition.
sub files_of_dir_matching($$$) {
	my ($dir, $condition, $context) = @_;
	
	my $children = $context->{Disketo_Instruction_Set::F_RESOURCES()}->{$dir};
	my @matching = grep { $condition->($_, $context) } @$children;
	return \@matching;
}
