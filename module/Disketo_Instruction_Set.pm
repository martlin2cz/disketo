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
sub op($$$$$$$$) {
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


# Returns the comands, as a hash mapping root command names to actual command nodes.
sub commands() {
	# -- compute primitive operations ----------------------------------
	
	my $load = op("load", "load", \&Disketo_Instructions::load, [], ["resources"], 
			"Loads the resources from the specified root folder or the file.",
			["roots"], { "roots" => "(the root resources)" });


	# -- compute primitive operations ----------------------------------
	
	my $count_files = op("count-files", "count-files", \&Disketo_Instructions::count_files, ["resources"], ["files counts"], 
			"Counts of files in each dir.",
			[], {});
	
	my $files_stats = op("files-stats", "files-stats", \&Disketo_Instructions::files_stats, ["resources"], ["files stats"], 
			"Obtains the stats of the files.",
			[], {});
		
	# -- compute composite operations ---------------------------------
	
	my $compute_custom = op("compute-custom", "custom", \&Disketo_Instructions::compute_custom, [], ["(user specified)"], 
			"Computes the custom meta.",
			[ "as-meta", "by" ],
			{ "as-meta" => "(meta name)",
			  "by" => "(computer function)" 
		});
		
	my $for_each_file = op("for-each-file", "for-each-file", \&Disketo_Instructions::compute_for_each_file, ["resources"], [],
		"For each file.",
		[ "what" ],
		{ "what" => {
			"files-stats" => $files_stats,
			"custom" => $compute_custom }
		});
		
	my $for_each_dir = op("for-each-dir", "for-each-dir", \&Disketo_Instructions::compute_for_each_dir, ["resources"], [],
		"For each dir.",
		[ "what" ],
		{ "what" => {
			"custom" => $compute_custom,
			"count-files" => $count_files }
		});
	
	my $compute = op("compute", "compute", \&Disketo_Instructions::compute, [], ["(user specified)"], 
		"Computes a meta.",
		[ "for-what" ],
		{ "for-what" => {
			"for-each-file" => $for_each_file,
			"for-each-dir" => $for_each_dir }
		});

# -- filter primitive operations ---------------------------------
	
	my $matching_custom_matcher = op("matching-custom-matcher", "matching-custom-matcher", \&Disketo_Instructions::matching_custom_matcher, [], [], 
			"Filters by specified matcher function",
			[ "by" ],
			{ "by" => "(matcher function)",
		});
		
	my $having_extension = op("having-extension", "having-extension", \&Disketo_Instructions::having_extension, [], [], 
			"Files having the specified extension.",
			[ "extension" ],
			{ "extension" => "(extension)",
		});
		
	my $more_than = op("more-than", "more-than", \&Disketo_Instructions::more_than, [], [], 
			"Files having more than specified number of files matching the condition.",
			[ "number" ],
			{ "number" => "(count)",
		});
		
	my $case_sensitive = op("case-sensitive", "case-sensitive", undef, [], [], 
			"Matches the pattern respecing the case",
			[], {});

	my $case_insensitive = op("case-insensitive", "case-insensitive", undef, [], [], 
			"Matches the pattern ignoring the case",
			[], {});

# -- filter composite operations ---------------------------------

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

	my $filter_files = op("filter-files", "files", \&Disketo_Instructions::filter_files, ["resources"], [], 
			"Filters files by given criteria",
			[ "matching" ],
			{ "matching" => {
				"matching-custom-matcher" => $matching_custom_matcher,
				"having-extension" => $having_extension,
				"matching-pattern" => $matching_pattern 
			}
		});

	my $filter_dirs = op("filter-dirs", "dirs", \&Disketo_Instructions::filter_dirs, ["resources"], [], 
			"Filters dirs by given criteria",
			[ "matching" ],
			{ "matching" => {
				"matching-custom-matcher" => $matching_custom_matcher,
				"matching-pattern" => $matching_pattern, #TODO: reuse
				"having-files" => $having_files
			}
		});

	my $filter = op("filter", "filter", \&Disketo_Instructions::filter, [], [], 
			"Filters by given criteria",
			[ "what" ],
			{ "what" => {
				"files" => $filter_files,
				"dirs" => $filter_dirs
			}
		});

	# -- print primitive operations ----------------------------------
	
	my $print_simply = op("print-simply", "simply", \&Disketo_Instructions::print_simply, [], [], 
			"Prints each resource by its complete path.",
			[], {});
		
	my $print_only_name = op("print-only-name", "only-name", \&Disketo_Instructions::print_only_name, [], [], 
			"Prints only the name of the resource.",
			[], {});
	
	my $print_custom = op("print-custom", "custom", \&Disketo_Instructions::print_custom, [], [], 
			"Prints each resource by the given function.",
			[ "printer" ],
			{ "printer" => "(printer function)" }
		);
	
	my $print_with_counts = op("print-with-counts", "with-counts", \&Disketo_Instructions::print_with_counts, ["files counts"], [], 
			"Prints each resource and number of its children.",
			[], {});
		
		
	my $print_stats = op("print-stats", "stats", \&Disketo_Instructions::print_stats, [], [], 
			"Prints the current context stats.",
			[], {});

	# -- print composite operations ---------------------------------
	
	my $print_files = op("print-files", "files", \&Disketo_Instructions::print_files, ["resources"], [],
		"Prints files.",
		[ "how" ],
		{ "how" => {
			"simply" => $print_simply,
			"only-name" => $print_only_name,
			"custom" => $print_custom }
		});
				
	my $print_dirs = op("print-dirs", "dirs", \&Disketo_Instructions::print_dirs, ["resources"], [],
		"Prints dirs.",
		[ "how" ],
		{ "how" => {
			"simply" => $print_simply, #TODO reuse from print_files
			"only-name" => $print_only_name,
			"with-counts" => $print_with_counts,
			"custom" => $print_custom }
		});
	
	my $print = op("print", "print", \&Disketo_Instructions::print, [], [], 
		"Prints given.",
		[ "what" ],
		{ "what" => {
			"files" => $print_files,
			"dirs" => $print_dirs,
			"stats" => $print_stats }
		});

	
	# -- x primitive operations ---------------------------------
	# -- x composite operations ---------------------------------


	# -- all together -------------------------------------------------

	my %commands = (
		"load" => $load,
		"compute" => $compute,
		# TODO group
		# TODO execute once
		# TODO print (debug) stats
		"filter" => $filter,
		"print" => $print
		
		#TODO all the remaining
	);
	
	return \%commands;

}
