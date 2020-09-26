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
# Shorthand for the operation(...).
sub op($$$$$$$$) {
	my ($id, $name, $method, $requires, $produces, $doc, $params, $valid_arguments) = @_;
	return operation($id, $name, $method, $requires, $produces, $doc, $params, $valid_arguments);
}

# Creates operation with no parameters/attributes at all.
# Shorthand for the operation(...).
sub nop($$$$$$) {
	my ($id, $name, $method, $requires, $produces, $doc) = @_;
	
	my $params = [];
	my $valid_arguments = {};
	return operation($id, $name, $method, $requires, $produces, $doc, $params, $valid_arguments);
}

# Creates operation with exactly one parameter/attribute.
# Shorthand for the operation(...).
sub sop($$$$$$$$) {
	my ($id, $name, $method, $requires, $produces, $doc, $param_name, $valid_param_value) = @_;
	
	my $params = [$param_name];
	my $valid_arguments = {$param_name => $valid_param_value};
	return operation($id, $name, $method, $requires, $produces, $doc, $params, $valid_arguments);
}


########################################################################
# METAS NAMES

sub M_RESOURCES() { "resources" }
sub M_USER_DEF() { "(user specified)" }

sub M_CHILDREN_COUNTS() { "children counts" }
sub M_FILE_STATS() { "file stats" }
sub M_FILES_GROUPS() { "files groups" }
sub M_DIRS_GROUPS() { "dirs groups" }

########################################################################
# Returns the comands, as a hash mapping root command names to actual command nodes.
sub commands() {
	# -- compute primitive operations ----------------------------------
	
	my $load = sop("load", "load", \&Disketo_Instructions::load, [], [M_RESOURCES], 
			"Loads the resources from the specified root folder or the file.",
			"roots", "(the root resources)");


	# -- compute primitive operations ----------------------------------
	
	my $count_files = nop("count-files", "count-files", \&Disketo_Instructions::count_files, [M_RESOURCES], [M_CHILDREN_COUNTS], 
			"Counts of files in each dir.");
	
	my $files_stats = nop("files-stats", "files-stats", \&Disketo_Instructions::files_stats, [M_RESOURCES], [M_FILE_STATS], 
			"Obtains the stats of the files.");
		
#	my $copy_of_meta = op("copy-of-meta", "copy-of-meta", \&Disketo_Instructions::copy_of_meta, [M_USER_DEF], [M_USER_DEF], 
#			"Copies the values of one specified meta and stores them to the second one.",
#			[ "source-meta-name", "destination-meta-name" ],
#			{ "source-meta-name" => "(source meta name)",
#			  "destination-meta-name" => "(destination meta name)" });
	
	# -- compute composite operations ---------------------------------
	
	my $compute_custom = op("compute-custom", "custom", \&Disketo_Instructions::compute_custom, [], [M_USER_DEF], 
			"Computes the custom meta.",
			[ "as-meta", "by" ],
			{ "as-meta" => "(meta name)",
			  "by" => "(computer function)" 
		});
		
	my $for_each_file = sop("for-each-file", "for-each-file", \&Disketo_Instructions::compute_for_each_file, [M_RESOURCES], [],
		"For each file.",
		"what", {
			"files-stats" => $files_stats, #TODO rename to "load stats"
			"custom" => $compute_custom });
#			"copy-of-meta" => $copy_of_meta 
		
	my $for_each_dir = sop("for-each-dir", "for-each-dir", \&Disketo_Instructions::compute_for_each_dir, [M_RESOURCES], [],
		"For each dir.",
		"what", {
			"custom" => $compute_custom,
			"count-files" => $count_files });
#			"copy-of-meta" => $copy_of_meta 
	
	my $compute = sop("compute", "compute", \&Disketo_Instructions::compute, [], [M_USER_DEF], 
		"Computes a meta.",
		"for-what", {
			"for-each-file" => $for_each_file,
			"for-each-dir" => $for_each_dir });


# -- group primitive operations ---------------------------------


	my $group_by_name = nop("group-by-name", "by-name", \&Disketo_Instructions::group_by_name, [], [], 
			"Groups the resources by their name.");
			
	my $group_by_name_and_size = nop("group-by-name-and-size", "by-name-and-size", \&Disketo_Instructions::group_by_name_and_size, [M_FILE_STATS], [], 
			"Groups the resources by their name and size.");
			
	my $group_by_custom = sop("group-by-custom", "by-custom", \&Disketo_Instructions::group_by_custom, [], [], 
			"Groups the resources by the specified groupper function.",
			"by", "(the groupper function)");

# -- group composite operations ---------------------------------
	my $group_files = sop("group-files", "files", \&Disketo_Instructions::group_files, [M_RESOURCES], [M_FILES_GROUPS], 
			"Groups the files by the given groupper.",
			"by", {
				"by-name" => $group_by_name,
				"by-name-and-size" => $group_by_name_and_size,
				"by-custom" => $group_by_custom });

	my $group_dirs = sop("group-dirs", "dirs", \&Disketo_Instructions::group_dirs, [M_RESOURCES], [M_DIRS_GROUPS], 
			"Groups the dirs by the given groupper.",
			"by", {
				"by-name" => $group_by_name,
				"by-custom" => $group_by_custom });

	my $group = sop("group", "group", \&Disketo_Instructions::group, [], [], 
		"Computes a some meta with the resources groupped by some groupper",
		"what", {
			"files" => $group_files,
			"dirs" => $group_dirs });

# -- execute primitive operations ---------------------------------
	my $execute = sop("execute", "execute", \&Disketo_Instructions::execute, [], [], 
		"Executes some function once during the process.",
		"what", "(operation to perform)");

# -- execute composite operations ---------------------------------

# nope ...

# -- filter primitive operations ---------------------------------
	
	my $matching_custom_matcher = sop("matching-custom-matcher", "matching-custom-matcher", \&Disketo_Instructions::matching_custom_matcher, [], [], 
			"Filters by specified matcher function",
			"by", "(matcher function)");
		
	my $having_extension = sop("having-extension", "having-extension", \&Disketo_Instructions::having_extension, [], [], 
			"Files having the specified extension.",
			"extension", "(extension)");
		
	my $more_than = sop("more-than", "more-than", \&Disketo_Instructions::more_than, [], [], 
			"Files having more than specified number of files matching the condition.",
			"number", "(count)");
		
	my $case_sensitive = nop("case-sensitive", "case-sensitive", undef, [], [], 
			"Matches the pattern respecing the case");

	my $case_insensitive = nop("case-insensitive", "case-insensitive", undef, [], [], 
			"Matches the pattern ignoring the case");

# -- filter composite operations ---------------------------------

# TODO 'matching only name pattern' and 'matching whole path pattern'

	my $matching_pattern = op("matching-pattern", "matching-pattern", \&Disketo_Instructions::matching_pattern, [], [], 
			"Matches the given pattern specified way",
			[ "pattern", "how" ],
			{	"pattern" => "(the pattern)",
				"how" => {
					"case-sensitive" => $case_sensitive,
					"case-insensitive" => $case_insensitive,
				}
		});
		
	my $having_files = 	op("having-files", "having-files", \&Disketo_Instructions::having_files, [], [], 
			"Directories having specified amount of files matching some condition.",
			[ "amount", "condition" ],
			{	"amount" => {
					"more-than" => $more_than,
					# TODO less-than, all-of-them, none-of-them, percentage, ...
				},
				"condition" => { # TODO reuse from filter_files
					"matching-custom-matcher" => $matching_custom_matcher,
					"having-extension" => $having_extension,
					"matching-pattern" => $matching_pattern 
				}
		});
		
	my $with_the_same_name = nop("with-the-same-name", "with-the-same-name", \&Disketo_Instructions::with_same_name, [M_FILES_GROUPS], [], 
			"Matches the resources which have the same name.");
	my $with_the_same_name_and_size = nop("with-the-same-name-and-size", "with-the-same-name-and-size", \&Disketo_Instructions::with_same_name_and_size, [M_FILES_GROUPS], [], 
			"Matches the resources which have the same name and size.");
	my $with_same_of_custom_group = sop("with-the-same-of-custom", "with-the-same-of-custom", \&Disketo_Instructions::with_same_of_custom_group, [M_USER_DEF], [], 
			"Matches the resources which have the specified amount of the resources with the specified custom groupper.",
			"groupper", "(the groupper function)");
		
	my $having_files_meta = op("having-files-meta", "having", \&Disketo_Instructions::having_meta, [], [], 
			"Filters files having given computed meta or value matching given criteria.",
			[ "criteria", "meta" ],
			{	"criteria" => {
					"more-than" => $more_than,
					# TODO less-than, all-of-them, none-of-them, percentage, ...
				},
				"meta" => { # TODO reuse from filter_files
					"with-the-same-name" => $with_the_same_name,
					"with-the-same-and-size" => $with_the_same_name_and_size,
					"with-the-same-of-custom" => $with_same_of_custom_group }
		});
	
	my $having_dirs_meta = op("having-dirs-meta", "having", \&Disketo_Instructions::having_meta, [], [], 
			"Filters dirs having given computed meta or value matching given criteria.",
			[ "criteria", "meta" ],
			{	"criteria" => {
					"more-than" => $more_than,
					# TODO less-than, all-of-them, none-of-them, percentage, ...
				},
				"meta" => { # TODO reuse from filter_files
					"with-the-same-name" => $with_the_same_name,
					"with-the-same-and-size" => $with_the_same_name_and_size,
					"with-the-same-of-custom" => $with_same_of_custom_group }
		});

	my $filter_files = sop("filter-files", "files", \&Disketo_Instructions::filter_files, [M_RESOURCES], [], 
			"Filters files by given criteria",
			"matching", {
				"matching-custom-matcher" => $matching_custom_matcher,
				"having-extension" => $having_extension,
				"matching-pattern" => $matching_pattern,
					#TODO "file-named"				
				"having" => $having_files_meta });

	my $filter_dirs = sop("filter-dirs", "dirs", \&Disketo_Instructions::filter_dirs, [M_RESOURCES], [], 
			"Filters dirs by given criteria",
			"matching", {
				"matching-custom-matcher" => $matching_custom_matcher,
				"matching-pattern" => $matching_pattern, #TODO: reuse
				"having-files" => $having_files, 
				#TODO "dir-named"
				"having" => $having_dirs_meta });

	my $filter = sop("filter", "filter", \&Disketo_Instructions::filter, [], [], 
			"Filters by given criteria",
			"what", {
				"files" => $filter_files,
				"dirs" => $filter_dirs });

	# -- print primitive operations ----------------------------------
	
	my $print_simply = nop("print-simply", "simply", \&Disketo_Instructions::print_simply, [], [], 
			"Prints each resource by its complete path.");
		
	my $print_only_name = nop("print-only-name", "only-name", \&Disketo_Instructions::print_only_name, [], [], 
			"Prints only the name of the resource.");
	
	my $print_custom = sop("print-custom", "custom", \&Disketo_Instructions::print_custom, [], [], 
			"Prints each resource by the given function.",
			"printer", "(printer function)");
	
	my $print_with_counts = nop("print-with-counts", "with-counts", \&Disketo_Instructions::print_with_counts, [M_CHILDREN_COUNTS], [], 
			"Prints each resource and number of its children.");
		
		
	my $print_stats = nop("print-stats", "stats", \&Disketo_Instructions::print_stats, [], [], 
			"Prints the current context stats.");
	
	
	my $print_size_in_bytes = nop("print-size-in-bytes", "in-bytes", \&Disketo_Instructions::print_size_in_bytes, [], [], 
			"Prints the file size in Bytes.");
	
	my $print_size_human_readable = nop("print-size-human-readable", "human-readable", \&Disketo_Instructions::print_size_human_readable, [], [], 
			"Prints the file size automatically in the B, kB, MB or GB based on its actual value.");

	# -- print composite operations ---------------------------------
	
	my $print_with_size = sop("print-with-size", "with-size", \&Disketo_Instructions::print_with_size, [M_FILE_STATS], [],
		"Prints the files and their size.",
		"how", {
			"in-bytes" => $print_size_in_bytes,
			"human-readable" => $print_size_human_readable });
	
	my $print_files = sop("print-files", "files", \&Disketo_Instructions::print_files, [M_RESOURCES], [],
		"Prints files.",
		"how", {
			"simply" => $print_simply,
			"only-name" => $print_only_name,
			"with-size" => $print_with_size,
			"custom" => $print_custom });
				
	my $print_dirs = sop("print-dirs", "dirs", \&Disketo_Instructions::print_dirs, [M_RESOURCES], [],
		"Prints dirs.",
		"how", {
			"simply" => $print_simply, #TODO reuse from print_files
			"only-name" => $print_only_name,
			"with-counts" => $print_with_counts,
			"custom" => $print_custom });
	
	my $print = sop("print", "print", \&Disketo_Instructions::print, [], [], 
		"Prints given.",
		"what", {
			"files" => $print_files,
			"dirs" => $print_dirs,
			"stats" => $print_stats });

	
	# -- x primitive operations ---------------------------------
	# -- x composite operations ---------------------------------


	# -- all together -------------------------------------------------

	my %commands = (
		"load" => $load,
		"compute" => $compute,
		"group" => $group,
		"execute" => $execute,
		# TODO print (debug) stats
		"filter" => $filter,
		"print" => $print
		
		#TODO all the remaining
	);
	
	return \%commands;

}

