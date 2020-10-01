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
# LOADS atomic

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
	
	return sub($$) {
		my ($file, $context) = @_;
		
		return Disketo_IO::load_stats_for_file($file);
	};
}

########################################################################
# COMPUTES atomic

sub children_count($) {
	my ($node) = @_;
	
	return sub($$) {
		my ($dir, $context) = @_;
		my @children = @{ $context->{M_RESOURCES}->{$dir} };
		return (scalar @children);
	};
}

sub directories_sizes($) {
	my ($node) = @_;
	
	return sub($$) {
		my ($dir, $context) = @_;
		my @children = @{ $context->{M_RESOURCES}->{$dir} };
		#TODO implementme
		return (scalar @children) . " PB";
	};
}

sub by_appling_custom_function_to_each($) {
	my ($node) = @_;

	my $computer = value($node, 0);
	
	return sub($$) {
		my ($resource, $context) = @_;
		return $computer->($resource, $context);
	};
}

sub compute_custom_meta($) {
	my ($node) = @_;

	my $function = value($node, 0);
	
	my $for_each_node = child($node, 1);
	my $for_each = $for_each_node->{"name"};

	return { "function" => $function, "for-what" => $for_each };
}


########################################################################
# COMPUTE composite

sub compute($) {
	my ($node) = @_;

	my $subresult = value($node, 0);
	my $meta_name = value($node, 1);

	my $function = $subresult->{"function"};
	my $for_what = $subresult->{"for-what"};
	
	if ($for_what eq "for-each-file") {
		return sub ($) {
			my ($context) = @_;
			Disketo_Engine::calculate_for_each_file($function, $meta_name, $context);
		};		
	}
	if ($for_what eq "for-each-dir")	 {
		return sub ($) {
			my ($context) = @_;
			Disketo_Engine::calculate_for_each_file($function, $meta_name, $context);
		};
	}
	die("Unsupported.");	
}

########################################################################
# GROUP atomic

sub group_by_name($) {
	my ($node) = @_;
	return sub($) {
		my ($resource, $context) = @_;
		my $name = basename($resource);
		return "$name";
	};
}

sub group_by_name_and_size($) {
	my ($node) = @_;
	return sub($) {
		my ($file, $context) = @_;
		my $name = basename($file);
		my $size = $context->{M_FILE_STATS}->{$file}->{"size"};
		return "$name$SEPARATOR$size";
	};
}

sub group_by_name_and_children_count($) {
	my ($node) = @_;
	return sub($) {
		my ($dir, $context) = @_;
		my $name = basename($dir);
		my $count = $context->{M_CHILDREN_COUNTS}->{$dir};
		return "$name$SEPARATOR$count";
	};
}

sub group_by_name_and_children_size($) {
	my ($node) = @_;
	return sub($) {
		my ($dir, $context) = @_;
		my $name = basename($dir);
		my $size = $context->{M_DIRS_SIZES}->{$dir};
		return "$name$SEPARATOR$size";
	};
}

sub group_by_custom($) {
	my ($node) = @_;
	my $function = value($node, 0);
	return sub($) {
		my ($resource, $context) = @_;
		return $function->($resource, $context);
	};
}

########################################################################
# GROUP composite

sub group_files($) {
	my ($node) = @_;
	my $groupper = delegate($node, 0);
	my $meta_name = delegate($node, 1);
	
	sub ($) {
		my ($context) = @_;
		Disketo_Engine::group_files($groupper, $meta_name, $context);
	};
}

sub group_dirs($) {
	my ($node) = @_;
	my $groupper = delegate($node, 0);
	my $meta_name = delegate($node, 1);
	
	sub ($) {
		my ($context) = @_;
		Disketo_Engine::group_dirs($groupper, $meta_name, $context);
	};
}

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
# FILTERS atomic

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

sub with_same_name($) {
	my ($node) = @_;
	
	return resource_to_meta("with same name"); #TODO meta name
}

sub with_same_name_and_size($) {
	my ($node) = @_;
	
	return resource_to_meta("with same name and size"); #TODO meta name
}

sub with_same_of_custom_group($) {
	my ($node) = @_;
	
	return resource_to_meta("with same custom group"); #TODO meta name
}

########################################################################
# FILTERS composite

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

sub dirs_having_children($) {
	my ($node) = @_;

	my $matching_what = delegate($node, 0);
	return sub($$) {
		my ($dir, $context) = @_;
		return files_of_dir_matching($dir, $matching_what, $context);
	};
}

sub of_the_same($) {
	my ($node) = @_;

	my $group_name = delegate($node, 0);
	return resource_to_meta($group_name);
}

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

sub filter_files($) {
	my ($node) = @_;

	my $matching = delegate($node, 0);
	return sub($) {
		my ($context) = @_;
		Disketo_Engine::filter_files($matching, $context);
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
# PRINTS atomic


sub print_stats($) {
	my ($node) = @_;

	return sub($) {
		my ($context) = @_;
		Disketo_Engine::context_stats($context);
	};
}

sub print_stats($) {
	my ($node) = @_;

	return sub($) {
		my ($context) = @_;
		Disketo_Engine::context_stats_debug($context); #TODO implementme!
	};
}

sub print_simply($) {
	my ($node) = @_;

	return sub($$) {
		my ($resource, $context) = @_;
		return $resource;
	};
}


sub print_only_name($) {
	my ($node) = @_;
	return resource_to_name();
}



sub print_custom($) {
	my ($node) = @_;

	my $printer = value($node, 0);
	return sub($$) {
		my ($resource, $context) = @_;
		return $printer->($resource, $context);
	};
}

sub print_with_counts($) {
	my ($node) = @_;

	return resource_to_resource_with_meta("directory children count"); #TODO meta name
}

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

sub print_custom_group($) {
	my ($node) = @_;
 
	my $group_meta_name = value($node, 0);
	return resource_to_resource_with_meta($group_meta_name);
}

sub print_of_the_same_name($) {
	my ($node) = @_;
 
	return resource_to_resource_with_meta("group meta field"); #TODO field name
}

sub print_of_the_same_name_and_size($) {
	my ($node) = @_;
 
	return resource_to_resource_with_meta("group meta field"); #TODO field name
}

sub print_of_the_same_name_and_children_size($) {
	my ($node) = @_;
 
	return resource_to_resource_with_meta("group meta field"); #TODO field name
}

sub print_of_the_same_name_and_children_count($) {
	my ($node) = @_;
 
	return resource_to_resource_with_meta("group meta field"); #TODO field name
}


########################################################################
# PRINTS composite


sub print_with_meta($) {
	my ($node) = @_;
	
	my $meta_name = value($node, 0);
	return resource_to_resource_with_meta($meta_name);
}

sub print_with_children_size($) {
	my ($node) = @_;
	
	my $size_printer = delegate($node, 0);
	return dir_to_dir_with_children_size($size_printer);
}

sub print_with_size($) {
	my ($node) = @_;
	
	my $size_printer = delegate($node, 0);
	return file_to_file_with_size($size_printer);
}

sub print_with_children($) {
	my ($node) = @_;

	my $printer = delegate($node, 0);
	return sub($$) {
		my ($dir, $context) = @_;
		my $children = $context->{M_RESOURCES}->{$dir};
		my $children_text = resources_to_names_text($children);
		return "$dir$SEPARATOR$children_text";
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
########################################################################
########################################################################
########################################################################
# FOLLOWING ARE DEPRECATED till the misc/utils/commons

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

sub having_meta($) {
	my ($having_meta_node) = @_;

	my $amount = delegate($having_meta_node, 0);
	my $groupper = delegate($having_meta_node, 1);

	return sub($$) {
		my ($resource, $context) = @_;
		my $resource_group_key = $groupper->($resource, $context);
		my $resources = $context->{Disketo_Instruction_Set::M_FILES_GROUPS()}->{$resource_group_key};
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



########################################################################
# GROUP

sub group($) {
	my ($group_node) = @_;
	return delegate($group_node, 0);
}

sub group_files($) {
	my ($group_files_node) = @_;

	my $groupper = delegate($group_files_node, 0);
	my $meta_name = Disketo_Instruction_Set::M_FILES_GROUPS();
	
	return sub($) {
		my ($context) = @_;
		Disketo_Engine::group_files($groupper, $meta_name, $context);
	};
}

sub group_dirs($) {
	my ($group_dirs_node) = @_;

	my $grouper = delegate($group_dirs_node, 0);
	my $meta_name = Disketo_Instruction_Set::M_DIRS_GROUPS();
	
	return sub($) {
		my ($context) = @_;
		Disketo_Engine::group_dirs($grouper, $meta_name, $context);
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
	my ($node) = @_;
	return resource_to_name();
}

sub print_with_counts($) {
	my ($node) = @_;

	return dir_to_dir_with_children_count();
}

sub print_with_size($) {
	my ($node) = @_;
	
	my $size_printer = delegate($node, 0);
	return file_to_file_with_size($size_printer);
}

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

sub print_custom($) {
	my ($node) = @_;

	my $printer = value($node, 0);
	return sub($$) {
		my ($resource, $context) = @_;
		return $printer->($resource, $context);
	};
}
	


########################################################################

#TODO all the remaining ...


########################################################################
########################################################################
# commons

sub resource_to_name() {
	return sub ($$) {
		my ($resource, $context) = @_;
		return basename($resource);
	};
}

sub resource_to_meta($) {
	my ($meta_name) = @_;
	
	return sub($) {
		my ($resource, $context) = @_;
		return $context->{$meta_name}->{$resource};
	};
}

sub file_to_file_with_size($) {
	my ($size_printer) = @_;
	
	return sub ($$) {
		my ($file, $context) = @_;
		my $stats = $context->{Disketo_Instruction_Set::M_FILE_STATS()}->{$file};
		my $size = $stats->{"size"};
		
		my $size_to_print = $size_printer->($size, $file, $context);
		return "$file$SEPARATOR$size_to_print";
	};
}

sub dir_to_dir_with_children_size($) {
	my ($size_printer) = @_;
	
	return sub ($$) {
		my ($dir, $context) = @_;
		my $size = $context->{Disketo_Instruction_Set::M_DIRS_SIZES()}->{$dir};
		
		my $size_to_print = $size_printer->($size, $dir, $context);
		return "$dir$SEPARATOR$size_to_print";
	};
}


sub resources_to_names_text($) {
	my ($resources) = @_;
	return "FIXME"; #TODO implementme resources -> map basename -> join
}

########################################################################
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
	
	my $children = $context->{Disketo_Instruction_Set::M_RESOURCES()}->{$dir};
	my @matching = grep { $condition->($_, $context) } @$children;
	return \@matching;
}

########################################################################
########################################################################

