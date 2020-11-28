#!/usr/bin/perl
use strict;

package Disketo_Instructions; 
my $VERSION=3.1.0;

use Data::Dumper;
use File::Basename;
use List::Util;

use Disketo_Instruction_Set;
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


# The fixed metas names
our $M_RESOURCES = "resources";
our $M_USER_DEF = "(user defined)";

# The extra custom metas names
our $M_FILE_STATS = "file-stats";

# The named metas
our $M_DIR_SUBTREE_COUNT = "dir-subtrees-count";
our $M_DIR_SUBTREE_SIZE = "dir-subtrees-size";

# The named groups
our $M_FILES_WITH_SAME_NAME = "files-with-same-name";
our $M_FILES_WITH_SAME_NAME_AND_SIZE = "files-with-same-name-and-size";
our $M_DIRS_WITH_SAME_NAME = "dirs-with-same-name";
our $M_DIRS_WITH_SAME_NAME_AND_SUBTREE_SIZE = "dirs-with-same-name-and-subtree-size";
our $M_DIRS_WITH_SAME_NAME_AND_SUBTREE_COUNT = "dirs-with-same-name-and-subtree-count";
our $M_DIRS_WITH_SAME_NAME_AND_CHILDREN_COUNT = "dirs-with-same-name-and-children-count";

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
#my ($package, $filename, $line) = caller;
#print("-> at $line\n"); #XXX debug
	return value_of_node($child);
}

# Call the "method" of the child_index-th argument of the given node.
sub delegate($$) {
	my ($node, $child_index) = @_;
	my $child = child_of_node($node, $child_index);
#my ($package, $filename, $line) = caller;
#print("=> at $line\n"); #XXX debug
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
# DEFAULT METHOD functions

# Delegates to its first child. If has less or more, fails.
sub pass($) {
	my ($node) = @_;
		
	if (scalar @{ $node->{"arguments"} } != 1) {
		die("Has not one child!");
	}
	
	delegate($node, 0); 
}

sub pass_value($) {
	my ($node) = @_;
	
	if (scalar @{ $node->{"arguments"} } != 1) {
		die("Has not one child!");
	}
	
	return value($node, 0);
}

# Incidates this method may be never called.
sub nope($) {
	my ($node) = @_;
	die("YOOU SHAAAL NOT ... be called!");
}

########################################################################
########################################################################
########################################################################
# LOADS PRIMITIVE

sub load_resources($) {
	my ($node) = @_;
	my $root_or_roots = value($node, 0);
	
	my $roots;
	if (ref($root_or_roots) eq "ARRAY") {
		$roots = $root_or_roots;
	} else {
		$roots = [ $root_or_roots ]; #FIXME TESTME
	}
	
	return sub($) {
		my ($context) = @_;
		Disketo_Engine::load($roots, $context);
	}
}

sub load_files_stats($) {
	my ($node) = @_;
	
	my $computer = sub($$) {
		my ($file, $context) = @_;
		return Disketo_IO::load_stats_for_file($file);
	};
	
	return sub($) {
		my ($context) = @_;
	
		Disketo_Engine::calculate_for_each_file($computer, $M_FILE_STATS, $context);
	}
}

########################################################################
########################################################################
########################################################################
# COMPUTES FOR DIR

sub directory_subtree_size($) {
	my ($node) = @_;
	
	return { "function" => \&compute_dir_to_subtree_size, 
			 "to-what" => "to-each-dir",
			 "as-meta" => $M_DIR_SUBTREE_SIZE };
}

sub directory_subtree_count($) {
	my ($node) = @_;
	
	return { "function" => \&compute_dir_to_subtree_count,
			 "to-what" => "to-each-dir",
			 "as-meta" => $M_DIR_SUBTREE_COUNT };
}

########################################################################
# COMPUTES CUSTOM

sub compute_custom_meta($) {
	my ($node) = @_;

	my $function = delegate($node, 0);
	
	my $for_each_node = child_of_node($node, 1);
	my $for_each = $for_each_node->{"name"};
	my $meta_name = delegate($node, 2);

	return { "function" => $function, 
			 "to-what" => $for_each,
			 "as-meta" => $meta_name };
}

sub by_appling_custom_function_to_each($) {
	my ($node) = @_;

	my $computer = value($node, 0);
	
	return create_apply_to_resource_fn($computer);
}


########################################################################
# COMPUTE COMPOSITES

sub compute($) {
	my ($node) = @_;

	my $subresult = delegate($node, 0);

	my $function = $subresult->{"function"};
	my $for_what = $subresult->{"to-what"};
	my $meta_name = $subresult->{"as-meta"};
	
	if ($for_what eq "to-each-file") {
		return sub ($) {
			my ($context) = @_;
			Disketo_Engine::calculate_for_each_file($function, $meta_name, $context);
		};		
	}
	if ($for_what eq "to-each-dir")	 {
		return sub ($) {
			my ($context) = @_;
			Disketo_Engine::calculate_for_each_dir($function, $meta_name, $context);
		};
	}
	die("Unsupported: $for_what.");	
}

########################################################################
########################################################################
########################################################################
# GROUP RESOURCES

sub group_by_custom($) {
	my ($node) = @_;
	
	my $function = value($node, 0);
	my $meta_name = delegate($node, 1);
	
	return { "function" => $function, "meta-name" => $meta_name };
}

########################################################################
# GROUP FILES

sub group_files_by_name($) {
	my ($node) = @_;
	return { "function" => \&resource_to_name,
			 "meta-name" => $M_FILES_WITH_SAME_NAME };
}

sub group_files_by_name_and_size($) {
	my ($node) = @_;
	return { "function" => \&file_to_name_and_size_simply, 
			 "meta-name" => $M_FILES_WITH_SAME_NAME_AND_SIZE };
}

sub group_files($) {
	my ($node) = @_;

	my $group_info = delegate($node, 0);
	my $groupper_fn = $group_info->{"function"};
	my $meta_name = $group_info->{"meta-name"};
	
	sub ($) {
		my ($context) = @_;
		Disketo_Engine::group_files($groupper_fn, $meta_name, $context);
	};
}

########################################################################
# GROUP DIRS

sub group_dirs_by_name($) {
	my ($node) = @_;
	return { "function" => \&resource_to_name,
			 "meta-name" => $M_DIRS_WITH_SAME_NAME };
}

sub group_dirs_by_name_and_children_count($) {
	my ($node) = @_;
	return { "function" => \&dir_to_name_and_children_count, 
			 "meta-name" => $M_DIRS_WITH_SAME_NAME_AND_CHILDREN_COUNT };
}

sub group_dirs_by_name_and_subtree_size($) {
	my ($node) = @_;
	return { "function" => \&dir_to_name_and_subtree_size, 
			 "meta-name" => $M_DIRS_WITH_SAME_NAME_AND_SUBTREE_SIZE };
}

sub group_dirs_by_name_and_subtree_count($) {
	my ($node) = @_;
	return { "function" => \&dir_to_name_and_subtree_count, 
			 "meta-name" => $M_DIRS_WITH_SAME_NAME_AND_SUBTREE_COUNT };
}

sub group_dirs($) {
	my ($node) = @_;
	
	my $group_info = delegate($node, 0);
	my $groupper_fn = $group_info->{"function"};
	my $meta_name = $group_info->{"meta-name"};
	
	sub ($) {
		my ($context) = @_;
		Disketo_Engine::group_dirs($groupper_fn, $meta_name, $context);
	};
}

########################################################################
########################################################################
########################################################################
# EXECUTE

sub execute($) {
	my ($node) = @_;
	
	my $operation = value($node, 0);
	return sub($) {
		my ($context) = @_;
		$operation->($context);
	}
}

########################################################################
########################################################################
########################################################################
# REDUCE

sub reduce_to_dirs_only($) {
	my ($node) = @_;
	
	return sub($$) {
		my ($file, $context) = @_;
		my $is_dir = (exists $context->{$M_RESOURCES}->{$file});
		return $is_dir;
	};
}

sub reduce_to_files_only($) {
	my ($node) = @_;
	
	return sub($$) {
		my ($file, $context) = @_;
		my $is_dir = (exists $context->{$M_RESOURCES}->{$file});
		return not $is_dir;
	};
}

sub reduce_files($) {
	my ($node) = @_;
	
	my $matching = delegate($node, 0);
	return sub($$) {
		my ($context) = @_;
		
		Disketo_Engine::filter_files($matching, $context);
	}
	
}

########################################################################
########################################################################
########################################################################
# FILTERS BY PATTERN

sub matching_pattern($) {
	my ($node) = @_;

	my $pattern = value($node, 0);
	
	if (is($node, 1, "case-sensitive")) {
		return sub($) {
			my ($resource, $context) = @_;
			return ($resource =~ /$pattern/);
		};
	}
	
	if (is($node, 1, "case-insensitive")) {
		return sub($) {
			my ($resource, $context) = @_;
			return ($resource =~ /$pattern/i);
		};
	}
	
	die("Unsupported.");
}

########################################################################
# FILTERS BY SIZE

sub filter_files_with_size($) {
	my ($node) = @_;

	my $size_condition = delegate($node, 0);
	
	return sub($$) {
		my ($file, $context) = @_;
		my $size = $context->{$M_FILE_STATS}->{$file}->{"size"};
		return $size_condition->($size);
	}	
}

sub filter_dirs_with_subtree_size($) {
	my ($node) = @_;

	my $size_condition = delegate($node, 0);
	
	return sub($$) {
		my ($dir, $context) = @_;
		my $size = $context->{$M_DIR_SUBTREE_SIZE}->{$dir};
		return $size_condition->($size);
	}	
}

sub bigger_than($) {
	my ($node) = @_;
	
	my $bigger_than_size = _obtain_condition_size($node);
	return sub($) {
		my ($size) = @_;
		return $size > $bigger_than_size;
	};
}

sub smaller_than($) {
	my ($node) = @_;
	
	my $smaller_than_size = _obtain_condition_size($node);
	return sub($) {
		my ($size) = @_;
		return $size < $smaller_than_size;
	};
}


sub _obtain_condition_size($) {
	my ($node) = @_;
	
	my $size = value($node, 0);
	if (is($node, 1, "bytes")) {
		$size *= 1;
	}
	if (is($node, 1, "kilobytes")) {
		$size *= 1024;
	}
	if (is($node, 1, "megabytes")) {
		$size *= 1024 * 1024;
	}
	
	return $size;
}


########################################################################
# FILTERS BY NUMBER

sub having($) {
	my ($node) = @_;

	my $how_much = delegate($node, 0);
	my $of_what = delegate($node, 1);
	
	return sub($$) {
		my ($resource, $context) = @_;
		my $items = $of_what->($resource, $context);
		return $how_much->($items, $context);
	};
}

sub more_than($) {
	my ($node) = @_;
	
	my $number = value($node, 0);
	return sub($$) {
		my ($resources, $context) = @_;
		return (scalar @$resources) > $number;
	};
}

sub less_than($) {
	my ($node) = @_;
	
	my $number = value($node, 0);
	return sub($$) {
		my ($resources, $context) = @_;
		return (scalar @$resources) < $number;
	};
}

sub none($) {
	my ($node) = @_;
	
	return sub($$) {
		my ($resources, $context) = @_;
		return (scalar @$resources) == 0;
	};
}


sub at_least_one($) {
	my ($node) = @_;
	
	return sub($$) {
		my ($resources, $context) = @_;
		return (scalar @$resources) >= 1;
	};
}



########################################################################
# FILTERS WITH SAME

sub of_the_same($) {
	my ($node) = @_;

	my $group_name = delegate($node, 0);		
	return create_resource_to_group_meta_fn($group_name);
}

sub dirs_with_same_name($) {
	my ($node) = @_;
	return $M_DIRS_WITH_SAME_NAME;
}

sub dirs_with_same_name_and_subtree_size($) {
	my ($node) = @_;
	return $M_DIRS_WITH_SAME_NAME_AND_SUBTREE_SIZE;
}

sub dirs_with_same_name_and_subtree_count($) {
	my ($node) = @_;
	return $M_DIRS_WITH_SAME_NAME_AND_SUBTREE_COUNT;
}

sub dirs_with_same_name_and_children_count($) {
	my ($node) = @_;
	return $M_DIRS_WITH_SAME_NAME_AND_CHILDREN_COUNT;
}

sub files_with_same_name($) {
	my ($node) = @_;
	return $M_FILES_WITH_SAME_NAME;
}

sub files_with_same_name_and_size($) {
	my ($node) = @_;
	return $M_FILES_WITH_SAME_NAME_AND_SIZE;
}

sub with_same_of_custom_group($) {
	my ($node) = @_;
	
	my $meta_name = value($node, 0);
	return $meta_name;
}

########################################################################
# FILTERS THE REST

sub matching_custom_matcher($) {
	my ($node) = @_;
	
	my $matcher = value($node, 0);
	return sub($) {
		my ($resources, $context) = @_;
		return $matcher->($resources, $context);
	};
}

sub named($) {
	my ($node) = @_;
	
	my $the_name = value($node, 0);
	return sub($) {
		my ($resource, $context) = @_;
		my $name = basename($resource);
		return $name eq $the_name;
	};
}

sub having_extension($) {
	my ($node) = @_;
	
	my $extension = value($node, 0);
	return sub($) {
		my ($file, $context) = @_;
		return ends_with($file, "." . $extension);
	};
}


########################################################################
# FILTERS FILES ...

sub filter_files($) {
	my ($node) = @_;

	my $matching = delegate($node, 0);
	return sub($) {
		my ($context) = @_;
		Disketo_Engine::filter_files($matching, $context);
	};
}

########################################################################
# FILTERS DIRS ...

sub dirs_having_children_files($) {
	my ($node) = @_;
	
	return \&resource_to_true;
}

sub dirs_having_children($) {
	my ($node) = @_;

	my $matching_what = delegate($node, 0);
	return sub($$) {
		my ($dir, $context) = @_;
		return files_of_dir_matching($dir, $matching_what, $context);
	};
}

sub filter_dirs($) {
	my ($node) = @_;

	my $matching = delegate($node, 0);
	return sub($) {
		my ($context) = @_;
		Disketo_Engine::filter_dirs($matching, $context);
	};
}

########################################################################
########################################################################
# PRINTS NON-RESOURCES

sub print_stats($) {
	my ($node) = @_;

	return sub($) {
		my ($context) = @_;
		Disketo_Engine::context_stats($context);
	};
}

sub print_debug_stats($) {
	my ($node) = @_;

	return sub($) {
		my ($context) = @_;
		Disketo_Engine::context_debug_stats($context);
	};
}

########################################################################
# PRINTS HOW

sub print_path($) {
	my ($node) = @_;
	return \&resource_to_resource;
}

sub print_only_name($) {
	my ($node) = @_;
	return \&resource_to_name;
}

sub print_custom($) {
	my ($node) = @_;

	my $printer = value($node, 0);
	return $printer;
}

sub print_custom_group($) {
	my ($node) = @_;
 
	my $group_meta_name = value($node, 0);
	return create_resource_to_group_meta_fn($group_meta_name);
}

sub print_with_meta($) {
	my ($node) = @_;
	
	my $meta_name = value($node, 0);
	return create_resource_to_meta_fn($meta_name);
}

########################################################################
# PRINTS WITH SIZEd

sub print_size_in_bytes($) {
	my ($node) = @_;

	return sub($$$) {
		my ($size, $resource, $context) = @_;
		return "$size B";	
	}
}

sub print_size_human_readable($) {
	my ($node) = @_;

	return sub($$$) {
		my ($size, $resource, $context) = @_;
		return Disketo_IO::size_to_human_readable($size);	
	}		
}

sub print_files_with_size($) {
	my ($node) = @_;
	
	my $size_printer = delegate($node, 0);
	return create_file_to_size_fn($size_printer);
}


########################################################################
# PRINTS DIR WITH CHILDREN/SUBTREE

sub print_dirs_with_children_count($) {
	my ($node) = @_;
	return \&dir_to_children_count;
}


sub print_dirs_with_subtree_count($) {
	my ($node) = @_;
	return create_resource_to_meta_fn($M_DIR_SUBTREE_COUNT);
}

sub print_dirs_with_subtree_size($) {
	my ($node) = @_;
	
	my $size_printer = delegate($node, 0);
	return create_dir_to_subtree_size_fn($size_printer);
}

sub print_dir_child_custom($) {
	my ($node) = @_;
	
	my $printer = value($node, 0);
	
	return $printer;
}

sub print_dir_child_name($) {
	my ($node) = @_;
	return \&resource_to_name;
}

sub print_dir_child_path($) {
	my ($node) = @_;
	return \&resource_to_resource;
}

sub print_dir_with_children($) {
	my ($node) = @_;

	if (is($node, 0, "count")) {
		return delegate($node, 0);
	}
	
	my $what_printer = delegate($node, 0);
	
	return sub ($$) {
		my ($dir, $context) = @_;
		
		my $children = $context->{$M_RESOURCES}->{$dir};
		my @mapped = map { $what_printer->($_) } @$children;
		return join($SEPARATOR, @mapped);
	};
}

########################################################################
# PRINTS WITH SAME

sub print_files_of_the_same_name($) {
	my ($node) = @_;
	return create_resource_to_group_meta_fn($M_FILES_WITH_SAME_NAME);
}

sub print_files_of_the_same_name_and_size($) {
	my ($node) = @_;
	return create_resource_to_group_meta_fn($M_FILES_WITH_SAME_NAME_AND_SIZE);
}

sub print_dirs_of_the_same_name($) {
	my ($node) = @_;
	return create_resource_to_group_meta_fn($M_DIRS_WITH_SAME_NAME);
}

sub print_of_the_same_name_and_size($) {
	my ($node) = @_;
	return create_resource_to_group_meta_fn($M_FILES_WITH_SAME_NAME_AND_SIZE);
}

sub print_of_the_same_name_and_subtree_size($) {
	my ($node) = @_;
	return create_resource_to_group_meta_fn($M_DIRS_WITH_SAME_NAME_AND_SUBTREE_SIZE);
}

sub print_of_the_same_name_and_subtree_count($) {
	my ($node) = @_;
	return create_resource_to_group_meta_fn($M_DIRS_WITH_SAME_NAME_AND_SUBTREE_COUNT);
}

sub print_of_the_same_name_and_children_count($) {
	my ($node) = @_;
	return create_resource_to_group_meta_fn($M_DIRS_WITH_SAME_NAME_AND_CHILDREN_COUNT);
}

########################################################################
# PRINTS RESOURCES

sub print_with($) {
	my ($node) = @_;
	
	my $with_what_printer = delegate($node, 0);
	
	return sub($$) {
		my ($resource, $context) = @_;
		my $withed = $with_what_printer->($resource, $context);
		my $with_stringified = meta_to_string($withed);
		return "$resource$SEPARATOR$with_stringified";
	};
}

sub print_files($) {
	my ($node) = @_;

	my $printer = delegate($node, 0);
	return sub($) {
		my ($context) = @_;
		Disketo_Engine::print_files($printer, $context);
	};
}

sub print_dirs($) {
	my ($node) = @_;

	my $printer = delegate($node, 0);
	return sub($) {
		my ($context) = @_;
		Disketo_Engine::print_dirs($printer, $context);
	};
}


########################################################################

#TODO all the remaining ...


########################################################################
########################################################################
# HELPER functions producing actual functions

sub create_apply_to_resource_fn($) {
	my ($function) = @_;
	
	return sub($$) {
		my ($resource, $context) = @_;
		return $function->($resource, $context);
	};
}

sub create_resource_to_meta_fn($) {
	my ($meta_name) = @_;
	
	return sub($$) {
		my ($resource, $context) = @_;

		return $context->{$meta_name}->{$resource};
	};
}

sub create_resource_to_group_meta_fn($) {
	my ($group_meta_name) = @_;
	
	return sub($$) {
		my ($resource, $context) = @_;
		my $group = $context->{$group_meta_name}->{$resource};
		my $without = remove_from_group($resource, $group);
		return $without;
	};
}


sub create_dir_to_subtree_size_fn($) {
	my ($size_printer) = @_;
	
	return sub($$) {
		my ($dir, $context) = @_;
		my $size = $context->{$M_DIR_SUBTREE_SIZE}->{$dir};
		my $size_to_print = $size_printer->($size);
		return "$size_to_print";
	};
}

sub create_file_to_size_fn($) {
	my ($size_printer) = @_;
	
	return sub($$) {
		my ($file, $context) = @_;
		my $size = $context->{$M_FILE_STATS}->{$file}->{"size"};
		my $size_to_print = $size_printer->($size);
		return "$size_to_print";
	};
}
	
########################################################################
# MAPPING functions <resorce> to <something>

sub resource_to_resource($$) {
	my ($resource, $context) = @_;
	return $resource;
}

sub resource_to_name($$) {
	my ($resource, $context) = @_;
	my $name = basename($resource);
	return $name;
}

sub resource_to_true($$) {
	my ($resource, $context) = @_;
	return 1;
}

sub file_to_name_and_size_simply($$) {
	my ($file, $context) = @_;
	my $name = basename($file);
	my $size = $context->{$M_FILE_STATS}->{$file}->{"size"};
	return "$name$SEPARATOR$size";
}
	
sub dir_to_name_and_children_count($$) {
	my ($dir, $context) = @_;
	my $name = basename($dir);
	my $children = $context->{$M_RESOURCES}->{$dir};
	my $count = scalar @$children;		
	return "$name$SEPARATOR$count";
}

sub dir_to_name_and_subtree_size($$) {
	my ($dir, $context) = @_;
	my $name = basename($dir);
	my $size = $context->{$M_DIR_SUBTREE_SIZE}->{$dir};
	return "$name$SEPARATOR$size";
}

sub dir_to_name_and_subtree_count($$) {
	my ($dir, $context) = @_;
	my $name = basename($dir);
	my $count = $context->{$M_DIR_SUBTREE_COUNT}->{$dir};
	return "$name$SEPARATOR$count";
}

sub dir_to_subtree_size($$) {
	my ($dir, $context) = @_;
	my $name = basename($dir);
	return $context->{$M_DIR_SUBTREE_SIZE}->{$dir};
}

sub dir_to_subtree_count($$) {
	my ($dir, $context) = @_;
	my $name = basename($dir);
	return $context->{$M_DIR_SUBTREE_COUNT}->{$dir};
}

sub dir_to_children_count($$) {
	my ($dir, $context) = @_;
	my $name = basename($dir);
	my $children = $context->{$M_RESOURCES}->{$dir};
	return scalar @$children;
}

sub dir_to_children_names($$) {
	my ($dir, $context) = @_;
	my $name = basename($dir);
	my $children = $context->{$M_RESOURCES}->{$dir};
	my @children_names = map { resource_to_name($_, $context) } @$children;
	return \@children_names;
}

sub dir_to_children_paths($$) {
	my ($dir, $context) = @_;
	my $name = basename($dir);
	my $children = $context->{$M_RESOURCES}->{$dir};
	return $children;
}

sub compute_dir_to_subtree_count($$) {
	my ($dir, $context) = @_;
	my $children = $context->{$M_RESOURCES}->{$dir};
	
	my @counts = map { 
		exists($context->{$M_DIR_SUBTREE_COUNT}->{$_}) 
		? $context->{$M_DIR_SUBTREE_COUNT}->{$_}
		: 1 } @$children;

	return 1 + List::Util::sum0(@counts);
} 

sub compute_dir_to_subtree_size($$) {
	my ($dir, $context) = @_;
	my $children = $context->{$M_RESOURCES}->{$dir};

	my @sizes = map { 
		exists($context->{$M_DIR_SUBTREE_SIZE}->{$_}) 
		? $context->{$M_DIR_SUBTREE_SIZE}->{$_}
		: $context->{$M_FILE_STATS}->{$_}->{"size"} } @$children;

	return $context->{$M_FILE_STATS}->{$dir}->{"size"} + List::Util::sum0(@sizes);
} 


sub meta_to_string($) {
	my ($meta_value) = @_;
	
	if (ref($meta_value) eq "ARRAY") {
		return join($SEPARATOR, @$meta_value);
	}
	
	if (ref($meta_value) eq "HASH") {
		return join($SEPARATOR, map { $_ . $SEPARATOR . $meta_value->{$_} } keys %$meta_value);
	}
	
	return $meta_value;
}

########################################################################
########################################################################
########################################################################
########################################################################
# UTILS

# Returns 1 if given text ends with given suffix. 
sub ends_with($$) {
	my ($text, $suffix) = @_;

	return ($suffix eq substr($text, -length($suffix)));
}

# Returns the files of the given dir in the given context, 
# which matches the given condition.
sub files_of_dir_matching($$$) {
	my ($dir, $condition, $context) = @_;
	
	my $children = $context->{$M_RESOURCES}->{$dir};
	my @matching = grep { $condition->($_, $context) } @$children;
	return \@matching;
}

# Creates copy of the given group NOT HAVING the given resource.
sub remove_from_group($$) {
	my ($resource, $group) = @_;
	my @group = @$group;
	my @without = grep { not($_ eq $resource) } @group;
	return \@without;
}

########################################################################
########################################################################
