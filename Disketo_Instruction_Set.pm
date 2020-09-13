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

sub TODO() {
	die("TODO");
}

sub op($$$$$$$) {
	my ($name, $method, $requires, $produces, $doc, $params, $valid_arguments) = @_;
	
	return {"name" => $name, 
			"method" => $method,
			"requires" => $requires,
			"produces" => $produces,
			"doc" => $doc,
			"params" => $params,
			"valid-args" => $valid_arguments };
}


sub commands() {
	# -- compute primitive operations ----------------------------------
	
	my $load = op("load", \&Disketo_Instructions::load, [], ["resources"], 
			"Loads the resources from the specified root folder or the file.",
			["roots"], { "roots" => "(the root resources)" });


	# -- compute primitive operations ----------------------------------
	
	my $count_files = op("count-files", \&Disketo_Instructions::count_files, ["resources"], ["files counts"], 
			"Counts of files in each dir.",
			[], {});
	
	my $files_stats = op("files-stats", \&Disketo_Instructions::files_stats, ["resources"], ["files stats"], 
			"Obtains the stats of the files.",
			[], {});
		
	# -- compute composite operations ---------------------------------
	
	my $compute_custom = op("compute-custom", \&Disketo_Instructions::compute_custom, [], ["(user specified)"], 
			"Computes the custom meta.",
			[ "as-meta", "by" ],
			{ "as-meta" => "(meta name)",
			  "by" => "(computer function)" 
		});
		
	my $for_each_file = op("for-each-file", \&Disketo_Instructions::compute_for_each_file, ["resources"], [],
		"For each file.",
		[ "what" ],
		{ "what" => {
			"files-stats" => $files_stats,
			"custom" => $compute_custom }
		});
		
	my $for_each_dir = op("for-each-dir", \&Disketo_Instructions::compute_for_each_dir, ["resources"], [],
		"For each dir.",
		[ "what" ],
		{ "what" => {
			"custom" => $compute_custom,
			"count-files" => $count_files }
		});
	
	my $compute = op("compute", \&Disketo_Instructions::compute, [], ["(user specified)"], 
		"Computes a meta.",
		[ "for-what" ],
		{ "for-what" => {
			"for-each-file" => $for_each_file,
			"for-each-dir" => $for_each_dir }
		});

# -- filter primitive operations ---------------------------------
	
	my $matching_custom_matcher = op("matching-custom-matcher", \&Disketo_Instructions::matching_custom_matcher, [], [], 
			"Filters by specified matcher function",
			[ "by" ],
			{ "by" => "(matcher function)",
		});
		
	my $having_extension = op("having-extension", \&Disketo_Instructions::having_extension, [], [], 
			"Files having the specified extension.",
			[ "extension" ],
			{ "extension" => "(extension)",
		});
		
	my $more_than = op("more-than", \&Disketo_Instructions::more_than, [], [], 
			"Files having more than specified number of files matching the condition.",
			[ "number" ],
			{ "number" => "(count)",
		});
		
	my $case_sensitive = op("case-sensitive", \&Disketo_Instructions::case_sensitive, [], [], 
			"Matches the pattern respecing the case",
			[], {});

	my $case_insensitive = op("case-insensitive", \&Disketo_Instructions::case_insensitive, [], [], 
			"Matches the pattern ignoring the case",
			[], {});

# -- filter composite operations ---------------------------------

	my $matching_pattern = op("matching-pattern", \&Disketo_Instructions::matching_pattern, [], [], 
			"Matches the given pattern specified way",
			[ "pattern", "how" ],
			{	"pattern" => "(the pattern)",
				"how" => {
					"case-sensitive" => $case_sensitive,
					"case-insensitive" => $case_insensitive,
				}
		});
		
	my $having_files = 	my $having_extension = op("having-files", \&Disketo_Instructions::having_files, [], [], 
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

	my $filter_files = op("filter-files", \&Disketo_Instructions::filter_files, ["resources"], [], 
			"Filters files by given criteria",
			[ "matching" ],
			{ "matching" => {
				"matching-custom-matcher" => $matching_custom_matcher,
				"having-extension" => $having_extension,
				"matching-pattern" => $matching_pattern 
			}
		});

	my $filter_dirs = op("filter-dirs", \&Disketo_Instructions::filter_dirs, ["resources"], [], 
			"Filters dirs by given criteria",
			[ "matching" ],
			{ "matching" => {
				"matching-custom-matcher" => $matching_custom_matcher,
				"matching-pattern" => $matching_pattern, #TODO: reuse
				"having-files" => $having_files
			}
		});

	my $filter = op("filter", \&Disketo_Instructions::filter, [], [], 
			"Filters by given criteria",
			[ "what" ],
			{ "what" => {
				"files" => $filter_files,
				"dirs" => $filter_dirs
			}
		});

	# -- print primitive operations ----------------------------------
	
	my $print_simply = op("print-simply", \&Disketo_Instructions::print_simply, [], [], 
			"Prints each resource by its complete path.",
			[], {});
		
	my $print_only_name = op("print-only-name", \&Disketo_Instructions::print_only_name, [], [], 
			"Prints only the name of the resource.",
			[], {});
	
	my $print_custom = op("print-custom", \&Disketo_Instructions::print_custom, [], [], 
			"Prints each resource by the given function.",
			[ "printer" ],
			{ "printer" => "(printer function)" }
		);
	
	my $print_with_counts = op("print-with-counts", \&Disketo_Instructions::print_with_counts, ["files counts"], [], 
			"Prints each resource and number of its children.",
			[], {});
		
		
	my $print_stats = op("stats", \&Disketo_Instructions::stats, [], [], 
			"Prints the current context stats.",
			[], {});

	# -- print composite operations ---------------------------------
	
	my $print_files = op("print-files", \&Disketo_Instructions::print_files, ["resources"], [],
		"Prints files.",
		[ "how" ],
		{ "how" => {
			"simply" => $print_simply,
			"only-name" => $print_only_name,
			"custom" => $print_custom }
		});
				
	my $print_dirs = op("print-dirs", \&Disketo_Instructions::print_dirs, ["resources"], [],
		"Prints dirs.",
		[ "how" ],
		{ "how" => {
			"simply" => $print_simply, #TODO reuse from print_files
			"only-name" => $print_only_name,
			"with-counts" => $print_with_counts,
			"custom" => $print_custom }
		});
	
	my $print = op("print", \&Disketo_Instructions::print, [], [], 
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

	# -- filters ------------------------------------------------------
	#~ my $file_filters = {
		#~ "with-extension" => $file_with_extension,
		#~ "matching-pattern" => $matching_patern,
		#~ "matching-custom" => $matching_custom, 
		#~ "by-meta" => $meta_spec };
	
	#~ my $dir_having_files = {
		#~ "amount_specifier"  => { # TODO FIXME
			#~ "at-least-than" => $at_least_than,
			#~ "no-more-than" => $no_more_than }, 
		
		#~ "matching" => $file_filters };
	
	#~ my $dirs_filters = {
		#~ "matching-pattern" => $matching_patern,
		#~ "matching-custom" => $matching_custom,
		#~ "having" => $dir_having_files };
	
	#~ my $filters = {
		#~ "files" => $file_filters,
		#~ "dirs" => $dirs_filters };

	#~ # -- prints --------------------------------------------------------
	#~ my $file_printers = {
		#~ "simply" => $print_simply,
		#~ "custom" => $print_custom };
		
	#~ my $dirs_printers = {
		#~ "simply" => $print_simply,
		#~ "custom" => $print_custom };
	
	#~ my $prints = {
		#~ "files" => $file_printers,
		#~ "dirs" => $dirs_printers };

	#~ # -- does ----------------------------------------------------------
	#~ my $does = {
		#~ "something" => $do_custom };

	#~ # -- the actual table-----------------------------------------------
	#~ my %table = (
		#~ "load" => $loads,
		#~ "compute" => $computes,
		#~ "filter" => $filters,
		#~ "print" => $prints,
		#~ "do" => $does
	#~ );
	
	#~ return \%table;
}

sub prepending_instruction($$) {
	my ($instruction, $prepending_command) = @_;
	 
	my $command = $instruction->{"command"};
	my $arguments = $instruction->{"arguments"};
	
	my $params = $command->{"params"};
	my $prepending_params = $prepending_command->{"params"};
	
	my $prepending_arguments; 
	if ($prepending_command->{"name"} eq "load") {
		$prepending_arguments = [];

	} elsif ($params eq $prepending_params) { #TODO FIXME operator intersection
		$prepending_arguments = $arguments;

	#TODO arguments := if $prepending_instruction takes XYZ, then pick from $instruction

	} else {
		print(Dumper($prepending_command, $command));
		die("Unimplemented prepend of " . $prepending_command->{"name"} . " before " . $command->{"name"});
	}
	
	return {"command" => $prepending_command, "arguments" => $prepending_arguments };
}

