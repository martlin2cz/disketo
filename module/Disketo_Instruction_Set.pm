#!/usr/bin/perl
use strict;

package Disketo_Instruction_Set; 
my $VERSION=3.1.0;
  
use Disketo_Instructions;
use Switch;
use Try::Tiny;
use Data::Dumper;

  
########################################################################
# The instruction set. Creates the mapping between the disketo script
# statements and particular perl functions.
########################################################################
# Creates the operation by the given informations. 
# The ID may be unique identifier of the node. Quite just for the debug purposes.
# The name must be the same name, which gets used in the valid_arguments,
# no need to be uniqe.
# The requires and produces are lists of metas names, produces and required by the command.
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
	
	#verify_method($id, $method); #TODO DEBUG
	
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

# Checks whether the method of the command exists.
sub verify_method($$) {
	my ($id, $method) = @_;

	try {
		$method->(undef);
		print STDERR ("$id: OK!\n");
	} catch {
		print STDERR ("$id: $_");
	};
}

########################################################################
# METAS NAMES
# The value names of the "meta field name" or "group meta field name" 
# parameter to be produced or required by that command
our $META_NAME_VALNAME_PROD = "(the meta field name to be produced)";
our $GROUP_META_NAME_VALNAME_PROD = "(the group meta field name to be produced)";
our $META_NAME_VALNAME_REQ = "(the meta field name required)";
our $GROUP_META_NAME_VALNAME_REQ = "(the group meta field name required)";

# just an shorthand
my $M_RESOURCES = $Disketo_Instructions::M_RESOURCES;
my $M_USER_DEF = $Disketo_Instructions::M_USER_DEF;

#######################################################################
########################################################################
# Returns the comands, as a hash mapping root command names to actual command nodes.
sub commands() {
	
	# ---------------------------------------------------------------
	# -- load primitive operations ----------------------------------
	
	my $resources = sop1("load-resources", "resources",
		\&Disketo_Instructions::load_resources, [], [$M_RESOURCES], 
		"Loads the resources from the specified root folder(s) or the file.",
		"what-roots?", "(the root resource or resources)");


	my $files_stats = sop0("files-stats", "files-stats",
		\&Disketo_Instructions::load_files_stats, [$M_RESOURCES], [$Disketo_Instructions::M_FILE_STATS], 
		"Loads the stats (file sizes, dates of modifications, ... ) of the files.");
	
	# -- load composite operations ----------------------------------
	
	my $load = sop1("load", "load", \&Disketo_Instructions::pass, [], [], 
		"Loads specified data from the disk.",
		"what?", [$resources, $files_stats]);

	# ---------------------------------------------------------------
	# -- compute primitive operations ----------------------------------
	

#	my $copy_of_meta = op("copy-of-meta", "copy-of-meta", \&Disketo_Instructions::copy_of_meta, [$M_USER_DEF], [$M_USER_DEF], 
#			"Copies the values of one specified meta and stores them to the second one.",
#			[ "source-meta-name", "destination-meta-name" ],
#			{ "source-meta-name" => "(source meta name)",
#			  "destination-meta-name" => "(destination meta name)" });

	my $directories_subtree_sizes = sop0("directories-subtree-sizes", "directories-subtree-sizes",
		\&Disketo_Instructions::directory_subtree_size, [$M_RESOURCES, $Disketo_Instructions::M_FILE_STATS], [$Disketo_Instructions::M_DIR_SUBTREE_SIZE],
		"Total size of subtree of each directory.");
	
	my $directories_subtree_counts = sop0("directories-subtree-counts", "directories-subtree-counts",
		\&Disketo_Instructions::directory_subtree_count, [$M_RESOURCES], [$Disketo_Instructions::M_DIR_SUBTREE_COUNT],
		"Total count of resources in the directory subtree.");
		
			
	my $to_each_file = sop0("to-each-file", "to-each-file", \&Disketo_Instructions::nope, [$M_RESOURCES], [],
		"Computes the new meta for each file.");
			
	my $to_each_dir = sop0("to-each-dir", "to-each-dir", \&Disketo_Instructions::nope, [$M_RESOURCES], [],
		"Computes the new meta for each directory.");
	
	my $applying_function = sop1("compute-by-appling-custom-function", "by-appling-function", 
		\&Disketo_Instructions::pass_value, [], [], 
		"Computes the meta field by applying the specified function to each of the resources.",
		"what-function?", "(the function)");

	my $compute_as_meta = sop1("compute-as-meta", "as-meta", \&Disketo_Instructions::pass_value, [], [$M_USER_DEF], 
		"Computes the meta field with specified name.",
		"what-meta?", $META_NAME_VALNAME_PROD);

	# -- compute composite operations ---------------------------------
	
	my $compute_custom_meta = sop3("compute-custom-meta", "custom-meta", \&Disketo_Instructions::compute_custom_meta, [], [], 
		"Computes the custom meta field.",
		"how?", [$applying_function],
		"for-each?", [$to_each_file, $to_each_dir],
		"as-what-meta?", [$compute_as_meta]);
	
	my $compute = sop1("compute", "compute", \&Disketo_Instructions::compute, [], [], 
		"Computes a meta field.",
		"what?", [$directories_subtree_sizes, $directories_subtree_counts, $compute_custom_meta]);

# ---------------------------------------------------------------
# -- group primitive operations ---------------------------------


	my $group_files_by_name = sop0("group-files-by-name", "by-name", 
		\&Disketo_Instructions::group_files_by_name, [], [$Disketo_Instructions::M_FILES_WITH_SAME_NAME], 
		"Groups the files by their names.");
	
	my $group_files_by_name_and_size = sop0("group-files-by-name-and-size", "by-name-and-size", 
		\&Disketo_Instructions::group_files_by_name_and_size, [$Disketo_Instructions::M_FILE_STATS], [$Disketo_Instructions::M_FILES_WITH_SAME_NAME_AND_SIZE], 
		"Groups the files by their name and size.");

	
	my $group_dirs_by_name = sop0("group-dirs-by-name", "by-name", 
		\&Disketo_Instructions::group_dirs_by_name, [], [$Disketo_Instructions::M_DIRS_WITH_SAME_NAME], 
		"Groups the dirs by their name.");
			
	my $group_dirs_by_name_and_subtree_size = sop0("group-dirs-by-name-and-subtree-size", "by-name-and-subtree-size",
		\&Disketo_Instructions::group_dirs_by_name_and_subtree_size, [$Disketo_Instructions::M_DIR_SUBTREE_SIZE], [$Disketo_Instructions::M_DIRS_WITH_SAME_NAME_AND_SUBTREE_SIZE], 
		"Groups the directories by their name and the total size of ancesting resources.");
	
	my $group_dirs_by_name_and_subtree_count = sop0("group-dirs-by-name-and-subtree-count", "by-name-and-subtree-count",
		\&Disketo_Instructions::group_dirs_by_name_and_subtree_count, [$Disketo_Instructions::M_DIR_SUBTREE_COUNT], [$Disketo_Instructions::M_DIRS_WITH_SAME_NAME_AND_SUBTREE_COUNT], 
		"Groups the directories by their name and the total number of ancesting resources.");

	my $group_dirs_by_name_and_children_count = sop0("group-dirs-by-name-and-children-count", "by-name-and-children-count",
		\&Disketo_Instructions::group_dirs_by_name_and_children_count, [], [$Disketo_Instructions::M_DIRS_WITH_SAME_NAME_AND_CHILDREN_COUNT], 
		"Groups the directories by their name and the number of child resources.");

	my $group_as_meta = sop1("group-as-meta", "as-meta", \&Disketo_Instructions::pass_value, [], [$M_USER_DEF], 
		"Groups it as a group with specified name.",
		"what-meta?", $GROUP_META_NAME_VALNAME_PROD);

	my $group_by_custom = sop2("group-by-custom", "by-custom-groupper", \&Disketo_Instructions::group_by_custom, [], [], 
		"Groups the resources by the specified groupper function.",
		"what-function?", "(the groupper function)",
		"as-meta?", [ $group_as_meta ]);
		
# -- group composite operations ---------------------------------

	my $group_files = sop1("group-files", "files", \&Disketo_Instructions::group_files, [$M_RESOURCES], [], 
		"Groups the files by the given groupper.",
		"by-what?", [ $group_by_custom, $group_files_by_name, $group_files_by_name_and_size ]);

	my $group_dirs = sop1("group-dirs", "dirs", \&Disketo_Instructions::group_dirs, [$M_RESOURCES], [], 
		"Groups the dirs by the given groupper.",
		"by-what?", [ $group_by_custom, $group_dirs_by_name, 
					$group_dirs_by_name_and_subtree_size, $group_dirs_by_name_and_subtree_count, $group_dirs_by_name_and_children_count ]);

	my $group = sop1("group", "group", \&Disketo_Instructions::pass, [], [], 
		"Computes a group with the resources groupped by some groupper",
		"what?", [ $group_files, $group_dirs ]);

# ---------------------------------------------------------------
# -- execute primitive operations ---------------------------------

	my $execute = sop1("execute", "execute", \&Disketo_Instructions::execute, [], [], 
		"Executes some function once during the process.",
		"what?", "(operation to perform)");

# ---------------------------------------------------------------
# -- filter primitive operations ---------------------------------
	
	my $matching_custom_matcher = sop1("matching-custom-matcher", "matching-custom-matcher",
		\&Disketo_Instructions::matching_custom_matcher, [], [], 
		"Filters by specified matcher function",
		"by-what?", "(matcher function)");
		
	#TODO dir-subtree of named vs. all dirs named
	my $named = sop1("named", "named", \&Disketo_Instructions::named, [], [], 
		"Resources having the specified name.",
		"what-name?", "(the resource name)");
		
	my $having_extension = sop1("having-extension", "having-extension", \&Disketo_Instructions::having_extension, [], [], 
		"Files having the specified extension.",
		"which-extension?", "(extension)");
		
	#TODO file bigger/smaller than
	#TODO dir subtree bigger/smaller than
	#TODO files older/younger than
		
	my $more_than = sop1("more-than", "more-than", \&Disketo_Instructions::more_than, [], [], 
		"Having more than specified number of resources matching the condition.",
		"what-number?", "(count)");
			
	my $less_than = sop1("less-than", "less-than", \&Disketo_Instructions::less_than, [], [], 
		"Having less than specified number of resources matching the condition.",
		"what-number?", "(count)");

	my $none = sop0("none", "none", \&Disketo_Instructions::none, [], [], 
		"Having exactly zero of resources matching the condition.");

	my $at_least_one = sop0("at-least-one", "at-least-one", \&Disketo_Instructions::at_least_one, [], [], 
		"Having at least one resource matching the condition.");

	my $at_least_one_more = sop0("at-least-one-more", "at-least-one-more", \&Disketo_Instructions::at_least_one_more, [], [], 
		"Having at least one and one more extra (2 in total) resource matching the condition.");
		
	my $case_sensitive = sop0("case-sensitive", "case-sensitive", \&Disketo_Instructions::nope, [], [], 
		"Matches the pattern respecing the case");

	my $case_insensitive = sop0("case-insensitive", "case-insensitive", \&Disketo_Instructions::nope, [], [], 
		"Matches the pattern ignoring the case");

	my $files_with_same_name = sop0("files-with-the-same-name", "name",
		\&Disketo_Instructions::files_with_same_name, [$Disketo_Instructions::M_FILES_WITH_SAME_NAME], [],  
		"Matches the files which have the same name.");

	my $dirs_with_same_name = sop0("dirs-with-the-same-name", "name",
		\&Disketo_Instructions::dirs_with_same_name, [$Disketo_Instructions::M_DIRS_WITH_SAME_NAME], [],  
		"Matches the dirs which have the same name.");
			
	my $files_with_same_name_and_size = sop0("files-with-the-same-name-and-size", "name-and-size",
		\&Disketo_Instructions::files_with_same_name_and_size, [$Disketo_Instructions::M_FILES_WITH_SAME_NAME_AND_SIZE], [],
		"Matches the dirs which have the same name and size.");
	
	my $dirs_with_same_name_and_subtree_count = sop0("dirs-with-the-same-name-and-subtree-count", "name-and-subtree-count",
		\&Disketo_Instructions::dirs_with_same_name_and_subtree_count, [$Disketo_Instructions::M_DIRS_WITH_SAME_NAME_AND_SUBTREE_COUNT], [],
		"Matches the dirs which have the same name and subtree resources count.");
	
	my $dirs_with_same_name_and_subtree_size = sop0("dirs-with-the-same-name-and-subtree-size", "name-and-subtree-size",
		\&Disketo_Instructions::dirs_with_same_name_and_subtree_size, [$Disketo_Instructions::M_DIRS_WITH_SAME_NAME_AND_SUBTREE_SIZE], [],
		"Matches the dirs which have the same name and total subtree resources size.");
		
	my $dirs_with_same_name_and_children_count = sop0("dirs-with-the-same-name-and-children-count", "name-and-children-count",
		\&Disketo_Instructions::dirs_with_same_name_and_children_count, [$Disketo_Instructions::M_DIRS_WITH_SAME_NAME_AND_CHILDREN_COUNT], [],
		"Matches the dirs which have the same name and children resources count.");		
			
	my $with_same_of_custom_group = sop1("with-the-same-of-custom", "custom-group",
		\&Disketo_Instructions::with_same_of_custom_group, [$M_USER_DEF], [], 
		"Matches the resources which have the specified amount of the resources with the specified custom groupper.",
		"what-group?", $GROUP_META_NAME_VALNAME_REQ);
		
# -- filter composite operations ---------------------------------

	my $matching_pattern = sop2("matching-pattern", "matching-pattern", \&Disketo_Instructions::matching_pattern, [], [], 
		"Matches the given pattern specified way.",
		"pattern?", "(the pattern)",
		"how?", [ $case_sensitive, $case_insensitive ]);
		
	my $files_of_the_same = sop1("files-of-the-same", "of-the-same", \&Disketo_Instructions::of_the_same, [], [], 
		"Filters files having given group.",
		"which-group?", [ $files_with_same_name, $files_with_same_name_and_size, $with_same_of_custom_group ]);
	
	my $files_having = sop2("files-having", "having", \&Disketo_Instructions::having, [], [], 
		"Filters files having the specified amount of element in the given group.",
		"how-much?", [ $less_than, $more_than, $none, $at_least_one, $at_least_one_more ],
		"of-what?", [ $files_of_the_same ]);
	
	my $dirs_having_children = sop1("dirs-having-children", "children", \&Disketo_Instructions::dirs_having_children, [], [], 
		"Filters dirs matching specified condition of its children.",
		"matching-what?", [ $matching_custom_matcher, $named, $matching_pattern, 
							$files_having, 
							$having_extension ]);
	
	my $dir_of_the_same = sop1("dirs-of-the-same", "of-the-same", \&Disketo_Instructions::of_the_same, [], [], 
		"Filters resources based on the group of the same resources.",
		"which-group?", [ $dirs_with_same_name, $dirs_with_same_name_and_subtree_count, $dirs_with_same_name_and_subtree_size, $with_same_of_custom_group ]);
	
	my $dirs_having = sop2("dirs-having", "having", \&Disketo_Instructions::having, [], [], 
		"Filters dirs having the specified amount of element in the given group.",
		"how-much?", [ $less_than, $more_than, $none, $at_least_one_more ],
		"of-what?", [ $dir_of_the_same, $dirs_having_children ]);
			
	my $filter_files = sop1("filter-files", "files", \&Disketo_Instructions::filter_files, [$M_RESOURCES], [], 
		"Filters files by given criteria",
		"matching-what?", [ $matching_custom_matcher, $named, $matching_pattern, 
							$files_having, 
							$having_extension ]);

	my $filter_dirs = sop1("filter-dirs", "dirs", \&Disketo_Instructions::filter_dirs, [$M_RESOURCES], [], 
		"Filters dirs by given criteria.",
		"matching-what?", [ $matching_custom_matcher, $named, $matching_pattern, 
							$dirs_having
							]);
							
	my $filter = sop1("filter", "filter", \&Disketo_Instructions::pass, [], [], 
		"Filters the resources by given criteria.",
		"what?", [ $filter_files, $filter_dirs ]);

# ---------------------------------------------------------------
# -- print common and shared operations --------------------------------
	
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

	my $print_with_meta = sop1("print-with-meta", "meta", \&Disketo_Instructions::print_with_meta, [$M_USER_DEF], [], 
		"Prints the resource and its corresponding meta field value.",
		"which-meta?", $META_NAME_VALNAME_REQ);

	my $print_with_custom_group = sop1("print-custom-group", "custom-group", 
		\&Disketo_Instructions::print_custom_group, [$M_USER_DEF], [], 
		"Prints the resources with resources in the same group specified by the given groupper function.",
		"what-group?", $GROUP_META_NAME_VALNAME_REQ);

	my $print_size_in_bytes = sop0("print-size-in-bytes", "in-bytes", \&Disketo_Instructions::print_size_in_bytes, [], [], 
		"Prints the file size in Bytes.");
	
	my $print_size_human_readable = sop0("print-size-human-readable", "human-readable", 
		\&Disketo_Instructions::print_size_human_readable, [], [], 
		"Prints the file size automatically in the B, kB, MB or GB based on its actual value.");

# -- print files specific operations --------------------------------
	
	my $print_files_with_size = sop1("print-files-with-size", "size", 
		\&Disketo_Instructions::print_files_with_size, [$Disketo_Instructions::M_FILE_STATS], [],
		"Prints the files and their size.",
		"how?", [ $print_size_in_bytes, $print_size_human_readable ]);
	
	my $print_files_with_same_name = sop0("print-files-with-same-name", "name",
		\&Disketo_Instructions::print_files_of_the_same_name, [$Disketo_Instructions::M_FILES_WITH_SAME_NAME], [], 
		"Prints the files with the same name as the current file.");
		
	my $print_files_with_same_name_and_size = sop0("print-files-with-same-name-and-size", "name-and-size",
		\&Disketo_Instructions::print_files_of_the_same_name_and_size, [$Disketo_Instructions::M_FILES_WITH_SAME_NAME_AND_SIZE], [], 
		"Prints the resources with the same name and size as the current resource.");

	my $print_files_with_its_group = sop1("print-files-with-its-group", "files-of-the-same", \&Disketo_Instructions::pass, [], [], 
		"Prints the files with all the files of the specified same property.",
		"what-groupper?", [$print_files_with_same_name, $print_with_custom_group, 
							$print_files_with_same_name_and_size]);
	
	my $print_files_with = sop1("print-files-with", "with", \&Disketo_Instructions::print_with, [], [],
		"Prints for each file its path and specified extra information.",
		"with-what?", [ $print_files_with_its_group, $print_with_meta,
						$print_files_with_size ]);
	
	my $print_files = sop1("print-files", "files", \&Disketo_Instructions::print_files, [$M_RESOURCES], [],
		"Prints files.",
		"how?", [ $print_simply, $print_only_name, $print_custom, $print_files_with ]);
			
# -- print dirs operations --------------------------------

	my $print_dir_with_children_count = sop0("print-dir-with-children-count", "count", 
		\&Disketo_Instructions::print_dirs_with_children_count, [], [], 
		"Prints each directory and number of its children.");
	
	my $print_dir_with_subtree_count = sop0("print-dir-with-subtree-count", "resources-count", 
		\&Disketo_Instructions::print_dirs_with_subtree_count, [], [], 
		"Prints each directory and number of resources in its subtree.");
	
	my $print_dir_with_children_custom = sop1("print-dir-with-children-custom", "custom", 
		\&Disketo_Instructions::print_dir_child_custom, [], [], 
		"Prints each directory and by custom printer also its children resources.",
		"how?", "(the children files printer function)");
	
	my $print_dir_with_children_paths = sop0("print-dir-with-children-paths", "paths", 
		\&Disketo_Instructions::print_dir_child_path, [], [], 
		"Prints each directory and paths of its children resources.");
	
	my $print_dir_with_children_names = sop0("print-dir-with-children-names", "names", 
		\&Disketo_Instructions::print_dir_child_name, [], [], 
		"Prints each directory and names of its children resources.");

	my $print_with_children_count = sop0("print-with-children-count", "count", 
		\&Disketo_Instructions::print_dirs_with_children_count, [], [], 
		"Prints each directory and number of its children.");
	
	my $print_dir_with_subtree_size = sop1("print-dir-with-subtree-size", "size", 
		\&Disketo_Instructions::print_dirs_with_subtree_size, [], [], 
		"Prints each directory and total size of resources in its subtree.",
		"how?", [ $print_size_in_bytes, $print_size_human_readable ]);
		
	my $print_dirs_with_same_name = sop0("print-dirs-with-same-name", "name",
		\&Disketo_Instructions::print_dirs_of_the_same_name, [$Disketo_Instructions::M_DIRS_WITH_SAME_NAME], [], 
		"Prints the dirs with the same name as the current dir.");

	my $print_dirs_with_same_name_and_children_count = sop0("print-with-same-name-and-children-count", "name-and-children-count",
		\&Disketo_Instructions::print_of_the_same_name_and_children_count, [$Disketo_Instructions::M_DIRS_WITH_SAME_NAME_AND_CHILDREN_COUNT], [], 
		"Prints the dirs with the same name and children count as the current dir.");
		
	my $print_dirs_with_same_name_and_subtree_size = sop0("print-with-same-name-and-subtree-size", "name-and-subtree-size",
		\&Disketo_Instructions::print_of_the_same_name_and_subtree_size, [$Disketo_Instructions::M_DIRS_WITH_SAME_NAME_AND_SUBTREE_SIZE], [], 
		"Prints the dirs with the same name and subtree size as the current dir.");
	
	my $print_dirs_with_same_name_and_subtree_count = sop0("print-with-same-name-and-subtree-resources-count", "name-and-subtree-resources-count",
		\&Disketo_Instructions::print_of_the_same_name_and_subtree_size, [$Disketo_Instructions::M_DIRS_WITH_SAME_NAME_AND_SUBTREE_COUNT], [], 
		"Prints the dirs with the same name and subtree resources count as the current dir.");


	my $print_dirs_with_its_group = sop1("print-dirs-with-its-group", "dirs-of-the-same", \&Disketo_Instructions::pass, [], [], 
		"Prints the dirs with all the resources it same group.",
		"what-groupper?", [$print_dirs_with_same_name, $print_with_custom_group, 
							$print_dirs_with_same_name_and_subtree_count, $print_dirs_with_same_name_and_subtree_size, 
							$print_dirs_with_same_name_and_children_count ]);
	
	my $print_dirs_with_subtree = sop1("print-dir-with-subtree", "subtree", 
		\&Disketo_Instructions::pass, [], [],
		"Prints the directory and something of its subtree",
		"subtree-what?", [ $print_dir_with_subtree_count, $print_dir_with_subtree_size ]);
	
	my $print_dirs_with_children = sop1("print-with-children", "children", 
		\&Disketo_Instructions::print_dir_with_children, [$M_RESOURCES], [], 
		"Prints each directory and something of its children",
		"children-what?", [ $print_dir_with_children_paths, $print_dir_with_children_names, $print_dir_with_children_custom,
							$print_dir_with_children_count ]);
	
	my $print_dirs_with = sop1("print-dirs-with", "with", \&Disketo_Instructions::print_with, [], [],
		"Prints for each dir its path and specified extra information.",
		"with-what?", [ $print_dirs_with_its_group, $print_with_meta,
						$print_dirs_with_children, $print_dirs_with_subtree ]);
	
				
	my $print_dirs = sop1("print-dirs", "dirs", \&Disketo_Instructions::print_dirs, [$M_RESOURCES], [],
		"Prints dirs.",
		"how?", [ $print_simply, $print_only_name, $print_custom, $print_dirs_with ]);

	
# -- print composite operations ---------------------------------
	
	
	my $print = sop1("print", "print", \&Disketo_Instructions::pass, [], [], 
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
		#TODO reduce files to files-only/dirs-only
		#TODO exclude hidden files/folders/resources
		"filter" => $filter,
		"print" => $print
		
		#TODO all the remaining
	);
	
	return \%commands;

}

