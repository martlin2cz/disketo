#!/usr/bin/perl
use strict;

package Disketo_Instruction_Set; 
my $VERSION=3.0.0;
  
use Disketo_Instructions;
use Switch;
use Data::Dumper;

  
########################################################################
# The instruction set. Creates the mapping between the disketo script
# statements and particular perl functions.
########################################################################
# Creates the operation by the given informations. 
# The ID may be unique identifier of the node. Quite just for the debug purposes.
# The name must be the same name, which gets used in the valid_arguments,
# no need to be uniqe.
# The requires and produces are lists of fields names, produces and required by the command.
# The doc is just human-readable documentation, description.
# The params is just the (ordered) list of the params names. Beware the order!
# The valid_arguments the mapping from the param name to its valid_argument. 
# The valid_argument is either the string (enclosed in brackets for the convience, please),
# indicating such parameter may accept the atomic value. 
# Or, the hash mapping the name to the any other command node. 
# This name must be the same as the name of the node.
# TODO rename: not operation, but command
sub operation($$$$$$$$) {
	my ($id, $name, $method, $requires, $produces, $doc, $params, $valid_arguments) = @_;
	
	return {"ID" => $id,
			"name" => $name, 
			"method" => $method,
			"requires" => $requires,
			"produces" => $produces,
			"doc" => $doc,
			"params" => $params,
			"valid-args" => $valid_arguments };
}

# Creates the complete operation.
# Shorthand for the operation(...),
# but valid_arguments listed is in format: {"param1?" => [$foo, $bar], "param2?" => "(baz)"}
sub op($$$$$$$$) {
	my ($id, $name, $method, $requires, $produces, $doc, $params, $valid_arguments_listed) = @_;
	
	my $valid_arguments = valid_childs_list_to_map($valid_arguments_listed);
	return operation($id, $name, $method, $requires, $produces, $doc, $params, $valid_arguments);
}

# Creates operation with no parameters/attributes at all.
# Shorthand for the operation(...),
# but with no params and valid_arguments.
sub sop0($$$$$$) {
	my ($id, $name, $method, $requires, $produces, $doc) = @_;
	
	my $params = [];
	my $valid_arguments = {};
	return operation($id, $name, $method, $requires, $produces, $doc, $params, $valid_arguments);
}

# Creates operation with exactly one parameter/attribute.
# Shorthand for the operation(...),
# but with only one param and valid_param_value in format [$foo, $bar] or "(baz)"
sub sop1($$$$$$$$) {
	my ($id, $name, $method, $requires, $produces, $doc, 
		$param1_name, $valid_param1_value) = @_;
	
	my $params = [$param1_name];
	my $valid_arguments = { $param1_name => valid_args_to_map($valid_param1_value) };
	return operation($id, $name, $method, $requires, $produces, $doc, $params, $valid_arguments);
}

# Creates operation with exactly two parameters/attributes.
# Shorthand for the operation(...),
# but with only two params and valid_param_value in format [$foo, $bar] or "(baz)"
sub sop2($$$$$$$$$$) {
	my ($id, $name, $method, $requires, $produces, $doc, 
		$param1_name, $valid_param1_value, $param2_name, $valid_param2_value) = @_;
	
	my $params = [$param1_name, $param2_name];
	my $valid_arguments = { $param1_name => valid_args_to_map($valid_param1_value),
						    $param2_name => valid_args_to_map($valid_param2_value) };
	return operation($id, $name, $method, $requires, $produces, $doc, $params, $valid_arguments);
}

# Creates operation with exactly three parameters/attributes.
# Shorthand for the operation(...),
# but with only three params and valid_param_value in format [$foo, $bar] or "(baz)"
sub sop3($$$$$$$$$$$$) {
	my ($id, $name, $method, $requires, $produces, $doc, 
		$param1_name, $valid_param1_value, $param2_name, $valid_param2_value, $param3_name, $valid_param3_value) = @_;
	
	my $params = [$param1_name, $param2_name, $param3_name];
	my $valid_arguments = { $param1_name => valid_args_to_map($valid_param1_value),
						    $param2_name => valid_args_to_map($valid_param2_value),
						    $param3_name => valid_args_to_map($valid_param3_value) };
	return operation($id, $name, $method, $requires, $produces, $doc, $params, $valid_arguments);
}


#######################################################################
# UTILS

# Takes the map {"param1?" => [$foo, $bar], "param2" => {"baz" => $baz}, "param3" => "(lorem)"} 
# and the [$foo, $bar] replaces by {"foo"=>$foo, "bar"=>$bar}
sub valid_childs_list_to_map($) {
	my ($valid_args_list) = @_;
	
	my %result = {};
	for my $param_name (keys %$valid_args_list) {
		my $valid_arg_param_value = $valid_args_list->{$param_name};
		
		my $new_valid_args = valid_args_to_map($valid_arg_param_value);
		
		$result{$param_name} = $new_valid_args;
	}
	return \%result;
}

# Takes the value [$foo], {"foo"=>$foo} or "(foo)" 
# and returns in the format {"foo"=>$foo}
sub valid_args_to_map($) {
	my ($valid_args) = @_;
	
	if (ref($valid_args) eq 'ARRAY') {
		my %new_valid_args = map { $_->{"name"} => $_ } @$valid_args;
		return \%new_valid_args
	} else {
		return $valid_args;
	}	
}

########################################################################
# FIELDS NAMES

sub F_RESOURCES() { "resources" }

sub FM_USER_DEF() { "(user specified)" }
sub FM_FILE_STATS() { "file stats" }
sub FM_CHILDREN_COUNTS() { "children counts" }
sub FM_DIRECTORIES_SIZES() { "directories sizes" }

sub FG_FILES_GROUPS() { "files groups" }
sub FG_DIRS_GROUPS() { "dirs groups" }

########################################################################
# Returns the comands, as a hash mapping root command names to actual command nodes.
sub commands() {
	
	# ---------------------------------------------------------------
	# -- load primitive operations ----------------------------------
	
	my $resources = sop1("load-resources", "load", \&Disketo_Instructions::load_resources, [], [F_RESOURCES], 
			"Loads the resources from the specified root folder(s) or the file.",
			"what-roots?", "(the root resource or resources)");


	my $files_stats = sop0("files-stats", "files-stats", \&Disketo_Instructions::files_stats, [F_RESOURCES], [FM_FILE_STATS], 
			"Loads the stats (file sizes, dates of modifications, ... ) of the files.");
	
	# -- load composite operations ----------------------------------
	
	my $load = sop1("load", "load", \&Disketo_Instructions::load, [], [], 
			"Loads specified data from the disk.",
			"what?", [$resources, $files_stats]);

	# ---------------------------------------------------------------
	# -- compute primitive operations ----------------------------------
	
		
#	my $copy_of_field = op("copy-of-field", "copy-of-field", \&Disketo_Instructions::copy_of_field, [M_USER_DEF], [M_USER_DEF], 
#			"Copies the values of one specified field and stores them to the second one.",
#			[ "source-field-name", "destination-field-name" ],
#			{ "source-field-name" => "(source field name)",
#			  "destination-field-name" => "(destination field name)" });

	my $children_count = sop0("children-count", "children-count", \&Disketo_Instructions::children_count, [F_RESOURCES], [FM_CHILDREN_COUNTS], 
			"Counts of files in each dir.");
	
	my $directories_sizes = sop0("directories-sizes", "directories-sizes", \&Disketo_Instructions::directories_sizes, [F_RESOURCES], [FM_DIRECTORIES_SIZES], 
			"Counts of files in each dir.");
			
	my $to_each_file = sop0("to-each-file", "to-each-file", undef, [F_RESOURCES], [],
			"Computes the new meta for each file.");
			
	my $to_each_dir = sop0("to-each-dir", "to-each-dir", undef, [F_RESOURCES], [],
			"Computes the new meta for each directory.");
	
	my $applying_function = sop1("compute-by-appling-function", "appling-function", \&Disketo_Instructions::by_appling_function_to_each, [], [], 
		"Computes the meta field by applying the specified function to each of the resources.",
		"what-function?", "(the function)");

	my $as_meta = sop1("compute-as-meta", "as-meta", \&Disketo_Instructions::as_meta, [], [], 
		"Computes the meta field with specified name.",
		"what-meta-name?", "(the meta field name)");

	# -- compute composite operations ---------------------------------
	
	my $compute_custom_meta = sop3("compute-custom-meta", "custom", \&Disketo_Instructions::compute_custom, [], [FM_USER_DEF], 
			"Computes the custom meta field.",
			"how?", [$applying_function],
			"for-each?", [$to_each_file, $to_each_dir],
			"as-what-meta?", [$as_meta]);
	
	my $compute = sop1("compute", "compute", \&Disketo_Instructions::compute, [], [FM_USER_DEF], 
		"Computes a meta field.",
		"what?", [$children_count, $directories_sizes, $compute_custom_meta]);


# ---------------------------------------------------------------
# -- group primitive operations ---------------------------------


	my $group_by_name = sop0("group-by-name", "by-name", \&Disketo_Instructions::group_by_name, [], [], 
			"Groups the resources by their name.");
			
	my $group_by_name_and_size = sop0("group-by-name-and-size", "by-name-and-size", \&Disketo_Instructions::group_by_name_and_size, [FM_FILE_STATS], [], 
			"Groups the resources by their name and size.");
	
	my $group_by_name_and_children_count = sop0("group-by-name-and-children-count", "by-name-and-children-count", \&Disketo_Instructions::group_by_name_and_children_count, [FM_CHILDREN_COUNTS], [], 
			"Groups the directoctories by their name and number of children.");
	
	my $group_by_name_and_children_size = sop0("group-by-name-and-children-size", "by-name-and-children-size", \&Disketo_Instructions::group_by_name_and_children_size, [FM_DIRECTORIES_SIZES], [], 
			"Groups the directoctories by their name and the size.");
	
	my $group_by_custom = sop1("group-by-custom", "by-custom", \&Disketo_Instructions::group_by_custom, [], [], 
			"Groups the resources by the specified groupper function.",
			"by-what-groupper?", "(the groupper function)");

# -- group composite operations ---------------------------------
	my $group_files = sop1("group-files", "files", \&Disketo_Instructions::group_files, [F_RESOURCES], [FG_FILES_GROUPS], 
			"Groups the files by the given groupper.",
			"by-what?", [ $group_by_name, $group_by_name_and_size, $group_by_custom ]);

	my $group_dirs = sop1("group-dirs", "dirs", \&Disketo_Instructions::group_dirs, [F_RESOURCES], [FG_DIRS_GROUPS], 
			"Groups the dirs by the given groupper.",
			"by-what?", [ $group_by_name, $group_by_name_and_children_count, $group_by_name_and_children_size, $group_by_custom ]);

	my $group = sop1("group", "group", \&Disketo_Instructions::group, [], [], 
		"Computes a group with the resources groupped by some groupper",
		"what?", [ $group_files, $group_dirs ]);

# ---------------------------------------------------------------
# -- execute primitive operations ---------------------------------
	my $execute = sop1("execute", "execute", \&Disketo_Instructions::execute, [], [], 
		"Executes some function once during the process.",
		"what?", "(operation to perform)");

# ---------------------------------------------------------------
# -- filter primitive operations ---------------------------------
	
	my $matching_custom_matcher = sop1("matching-custom-matcher", "matching-custom-matcher", \&Disketo_Instructions::matching_custom_matcher, [], [], 
			"Filters by specified matcher function",
			"by-what?", "(matcher function)");
	
	my $named = sop1("named", "named", \&Disketo_Instructions::named, [], [], 
			"Resources having the specified name.",
			"what-name?", "(the resource name)");
		
	my $having_extension = sop1("having-extension", "having-extension", \&Disketo_Instructions::having_extension, [], [], 
			"Files having the specified extension.",
			"which-extension?", "(extension)");
		
	my $more_than = sop1("more-than", "more-than", \&Disketo_Instructions::more_than, [], [], 
			"Having more than specified number of resources matching the condition.",
			"what-number?", "(count)");
			
	my $less_than = sop1("less-than", "less-than", \&Disketo_Instructions::less_than, [], [], 
			"Having less than specified number of resources matching the condition.",
			"what-number?", "(count)");
	my $none = sop0("none", "none", \&Disketo_Instructions::none, [], [], 
			"Having exactly zero of resources matching the condition.");
		
	my $case_sensitive = sop0("case-sensitive", "case-sensitive", undef, [], [], 
			"Matches the pattern respecing the case");

	my $case_insensitive = sop0("case-insensitive", "case-insensitive", undef, [], [], 
			"Matches the pattern ignoring the case");

	my $with_same_name = sop0("with-the-same-name", "name", \&Disketo_Instructions::with_same_name, [FG_FILES_GROUPS], [], 
			"Matches the resources which have the same name.");
			
	my $with_same_name_and_size = sop0("with-the-same-name-and-size", "name-and-size", \&Disketo_Instructions::with_same_name_and_size, [FG_FILES_GROUPS], [], 
			"Matches the resources which have the same name and size.");
			
	my $with_same_of_custom_group = sop1("with-the-same-of-custom", "custom-group", \&Disketo_Instructions::with_same_of_custom_group, [FM_USER_DEF], [], 
			"Matches the resources which have the specified amount of the resources with the specified custom groupper.",
			"what-groupper?", "(the groupper function)");
		

# -- filter composite operations ---------------------------------

	my $matching_pattern = sop2("matching-pattern", "matching-pattern", \&Disketo_Instructions::matching_pattern, [], [], 
			"Matches the given pattern specified way.",
			"pattern?", "(the pattern)",
			"how?", [ $case_sensitive, $case_insensitive ]);
		
	my $dirs_having_children = sop1("dirs-having-children", "children", \&Disketo_Instructions::dirs_having_children, [], [], 
			"Filters dirs matching specified condition of its children.",
			"matching-what?", [ $matching_custom_matcher, $having_extension, $matching_pattern ]);
	
	my $dir_of_the_same = sop1("dirs-of-the-same", "of-the-same", \&Disketo_Instructions::of_the_same, [], [], 
			"Filters resources based on the group of the same resources.",
			"which-group?", [ $with_same_name, $with_same_name_and_size, $with_same_of_custom_group ]);
	
	my $dirs_having = sop2("dirs-having", "having", \&Disketo_Instructions::dirs_having, [], [], 
			"Filters dirs having the specified amount of element in the given group.",
			"how-much?", [ $less_than, $more_than, $none ],
			"what?", [ $dir_of_the_same, $dirs_having_children ]);
			
	my $files_of_the_same = sop1("files-of-the-same", "of-the-same", \&Disketo_Instructions::files_of_the_same, [], [], 
			"Filters files having given group.",
			"which-group?", [ $with_same_name, $with_same_name_and_size, $with_same_of_custom_group ]);
	
	my $files_having = sop2("files-having", "having", \&Disketo_Instructions::files_having, [], [], 
			"Filters files having the specified amount of element in the given group.",
			"how-much?", [ $less_than, $more_than, $none ],
			"what?", [ $files_of_the_same ]);
	
	my $filter_files = sop1("filter-files", "files", \&Disketo_Instructions::filter_files, [F_RESOURCES], [], 
			"Filters files by given criteria",
			"matching-what?", [ $matching_custom_matcher, $named, $matching_pattern, 
							$files_having, 
							$having_extension ]);

	my $filter_dirs = sop1("filter-dirs", "dirs", \&Disketo_Instructions::filter_dirs, [F_RESOURCES], [], 
			"Filters dirs by given criteria.",
			"matching-what?", [ $matching_custom_matcher, $named, $matching_pattern, 
							$dirs_having
							 ]);
							
	my $filter = sop1("filter", "filter", \&Disketo_Instructions::filter, [], [], 
			"Filters the resources by given criteria.",
			"what?", [ $filter_files, $filter_dirs ]);

# ---------------------------------------------------------------
# -- print primitive operations ----------------------------------
	
	my $print_stats = sop0("print-stats", "stats", \&Disketo_Instructions::print_stats, [], [], 
			"Prints the current context stats.");

	my $print_debug_stats = sop0("print-debug-stats", "debug-stats", \&Disketo_Instructions::print_debug_stats, [], [], 
			"Prints the more precise informations about the current context.");
	
	my $print_simply = sop0("print-simply", "simply", \&Disketo_Instructions::print_simply, [], [], 
			"Prints each resource by its complete path.");
		
	my $print_only_name = sop0("print-only-name", "only-name", \&Disketo_Instructions::print_only_name, [], [], 
			"Prints only the name of the resource.");
	
	my $print_custom = sop1("print-custom", "custom", \&Disketo_Instructions::print_custom, [], [], 
			"Prints each resource by the given function.",
			"how?", "(printer function)");
	
	my $print_with_children_count = sop0("print-with-children-count", "with-children-count", \&Disketo_Instructions::print_with_counts, [FM_CHILDREN_COUNTS], [], 
			"Prints each resource and number of its children.");
	
	my $print_only_name = sop0("print-only-name", "only-name", \&Disketo_Instructions::print_only_name, [], [], 
			"Prints only the name of the resource.");
	
	my $print_size_in_bytes = sop0("print-size-in-bytes", "in-bytes", \&Disketo_Instructions::print_size_in_bytes, [], [], 
			"Prints the file size in Bytes.");
	
	my $print_size_human_readable = sop0("print-size-human-readable", "human-readable", \&Disketo_Instructions::print_size_human_readable, [], [], 
			"Prints the file size automatically in the B, kB, MB or GB based on its actual value.");

	my $print_with_custom_group = sop1("print-custom-group", "custom-group", \&Disketo_Instructions::custom_group, [], [], 
			"Prints the resources with resources in the same group specified by the given groupper function.",
			"what-groupper?", "(the groupper function)");
	
	my $print_with_same_name = sop0("print-with-same-name", "of-the-same-name", \&Disketo_Instructions::of_the_same_name, [], [], 
			"Prints the resources with the same name as the current resource.");
	
	my $print_with_same_name_and_size = sop0("print-with-same-name-and-size", "of-the-same-name-and-size", \&Disketo_Instructions::of_the_same_name_and_size, [], [], 
			"Prints the resources with the same name and size as the current resource.");
			
	my $print_with_same_name_and_children_size = sop0("print-with-same-name-and-children-size", "of-the-same-name-and-children-size", \&Disketo_Instructions::of_the_same_name_and_size, [], [], 
			"Prints the dirs with the same name and children size as the current dir.");
	
	my $print_with_same_name_and_children_count = sop0("print-with-same-name-and-children-count", "of-the-same-name-and-children-count", \&Disketo_Instructions::of_the_same_name_and_size, [], [], 
			"Prints the dirs with the same name and children count as the current dir.");

# -- print composite operations ---------------------------------
	
	my $print_files_with_its_group = sop1("print-files-with-its-group", "with-its-group", \&Disketo_Instructions::print_with_its_group, [], [FG_FILES_GROUPS], 
			"Prints the files with all the resources it same group.",
			"what-groupper?", [$print_with_same_name, $print_with_custom_group, 
								$print_with_same_name_and_size]);
			
	my $print_dirs_with_its_group = sop1("print-dirs-with-its-group", "with-its-group", \&Disketo_Instructions::print_with_its_group, [], [FG_DIRS_GROUPS], 
			"Prints the dirs with all the resources it same group.",
			"what-groupper?", [$print_with_same_name, $print_with_custom_group, 
								$print_with_same_name_and_children_size, $print_with_same_name_and_children_count]);
	
	my $print_with_meta = sop1("print-with-meta", "with-meta", \&Disketo_Instructions::print_with_meta, [], [FM_USER_DEF], 
			"Prints the resource and its corresponding meta field value.",
			"which-meta?", "(the meta field name)");
	
	my $print_with_children_size = sop1("print-with-children-size", "with-children-size", \&Disketo_Instructions::print_with_children_size, [FM_DIRECTORIES_SIZES], [], 
			"Prints each resource and size of its children.",
			"how?", [ $print_size_in_bytes, $print_size_human_readable ]);
	
	my $print_with_size = sop1("print-with-size", "with-size", \&Disketo_Instructions::print_with_size, [FM_FILE_STATS], [],
		"Prints the files and their size.",
		"how?", [ $print_size_in_bytes, $print_size_human_readable ]);
	
	my $print_with_children_names = sop0("print-with-children", "with-children", \&Disketo_Instructions::print_with_children, [], [], 
		"Prints each directory and its children.");
	
	
	my $print_files = sop1("print-files", "files", \&Disketo_Instructions::print_files, [F_RESOURCES], [],
		"Prints files.",
		"how?", [ $print_simply, $print_only_name, $print_custom, $print_files_with_its_group, $print_with_meta,
				$print_with_size ]);
				
	my $print_dirs = sop1("print-dirs", "dirs", \&Disketo_Instructions::print_dirs, [F_RESOURCES], [],
		"Prints dirs.",
		"how?", [ $print_simply, $print_only_name, $print_custom, $print_dirs_with_its_group, $print_with_meta,
				$print_with_children_names, $print_with_children_size, $print_with_children_count ]);
	
	my $print = sop1("print", "print", \&Disketo_Instructions::print, [], [], 
		"Prints given.",
		"what?", [ $print_files, $print_dirs, $print_stats, $print_debug_stats ]);

	
# ---------------------------------------------------------------
# -- x primitive operations ---------------------------------
# -- x composite operations ---------------------------------

# -----------------------------------------------------------------
# -- all together -------------------------------------------------

	my %commands = (
		"load" => $load,
		"compute" => $compute,
		"group" => $group,
		"execute" => $execute,
		"filter" => $filter,
		"print" => $print
		
		#TODO all the remaining
	);
	
	return \%commands;

}

