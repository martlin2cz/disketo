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

sub op($$$$$$) {
	my ($name, $method, $requires, $produces, $doc, $params) = @_;
	
	return {"name" => $name, 
			"method" => $method,
			"requires" => $requires,
			"produces" => $produces,
			"doc" => $doc,
			"params" => $params };
}


sub commands() {
	#~ # -- computes instructions -----------------------------------------
	
	#~ my $load_all = TODO();
	
	#~ # -- computes instructions -----------------------------------------
	
	#~ my $compute_custom = subop(\&Disketo_Instructions::compute_custom_meta, ["meta-name", "by"], [], "(user specified)", "Computes the new meta.");
	#~ my $load_files_stats = TODO();

	#~ # -- filter instructions -----------------------------------------
	
	#~ my $file_with_extension = TODO();
	#~ my $matching_patern = TODO();
	#~ my $matching_custom = TODO();
	#~ my $meta_spec = TODO();
	
	#~ my $at_least_than = TODO();
	#~ my $no_more_than = TODO();
	
	#~ # -- print instructions -----------------------------------------
	
	#~ my $print_simply = TODO();
	#~ my $print_custom = TODO();
	
	#~ # -- does instructions -----------------------------------------
	
	#~ my $do_custom = TODO();
	
	#~ # -- loads ---------------------------------------------------------
	
	#~ my $loads = {
		#~ "files" => $load_all,
		#~ "dirs" => $load_all,
		#~ "resources" => $load_all,
		#~ "files-and-dirs" => $load_all
	#~ };
	
	# -- compute primitive operations ----------------------------------
	
	my $count_files = op("count-files", \&Disketo_Instructions::count_files, [], ["files counts"], 
			"Counts of files in each dir.",
			{}
		);
	
	my $files_stats = op("files-stats", \&Disketo_Instructions::files_stats, [], ["files stats"], 
			"Obtains the stats of the files.",
			{}
		);
		
	# -- compute composite operations ---------------------------------
	
	my $compute_custom = op("compute-custom", \&Disketo_Instructions::compute_custom, [], ["(user specified)"], 
			"Computes the custom meta.",
			{ "by" => undef, 
			  "as-meta" => undef
		});
		
	my $for_each_file = op("for-each-file", \&Disketo_Instructions::for_each_file, [], [],
		"For each file.",
		{ "what" => {
			"files-stats" => $files_stats,
			"custom" => $compute_custom }
		});
		
	my $for_each_dir = op("for-each-dir", \&Disketo_Instructions::for_each_dir, [], [],
		"For each dir.",
		{ "what" => {
			"custom" => $compute_custom,
			"count-files" => $count_files }
		});
	
	my $compute = op("compute", \&Disketo_Instructions::compute, [], ["(user specified)"], 
		"Computes a meta.",
		{ "for_what" => {
			"for-each-file" => $for_each_file,
			"for-each-dir" => $for_each_dir }
		});

# -- filter primitive operations ---------------------------------
	
	my $matching_custom_matcher = op("matching-custom-matcher", \&Disketo_Instructions::matching_custom_matcher, [], [], 
			"Filters by specified matcher function",
			{ "by" => undef,
		});
		
	my $having_extension = op("having-extension", \&Disketo_Instructions::having_extension, [], [], 
			"Files having the specified extension.",
			{ "extension" => undef,
		});
		
	my $more_than = op("more-than", \&Disketo_Instructions::more_than, [], [], 
			"Files having more than specified number of files matching the condition.",
			{ "number" => undef,
		});
		
	my $case_sensitive = op("case-sensitive", \&Disketo_Instructions::case_sensitive, [], [], 
			"Matches the pattern respecing the case",
			{});

	my $case_insensitive = op("case-insensitive", \&Disketo_Instructions::case_insensitive, [], [], 
			"Matches the pattern ignoring the case",
			{});

# -- filter composite operations ---------------------------------

	my $matching_pattern = op("matching-pattern", \&Disketo_Instructions::matching_pattern, [], [], 
			"Matches the given pattern specified way",
			{	"pattern" => undef,
				"how" => {
					"case-sensitive" => $case_sensitive,
					"case-insensitive" => $case_insensitive,
				}
		});
		
	my $having_files = 	my $having_extension = op("having-files", \&Disketo_Instructions::having_files, [], [], 
			"Directories having specified amount of files matching some condition.",
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

	my $filter_files = op("filter-files", \&Disketo_Instructions::filter_files, [], [], 
			"Filters files by given criteria",
			{ "matching" => {
				"matching-custom-matcher" => $matching_custom_matcher,
				"having-extension" => $having_extension,
				"matching-pattern" => $matching_pattern 
			}
		});

	my $filter_dirs = op("filter-dirs", \&Disketo_Instructions::filter_dirs, [], [], 
			"Filters dirs by given criteria",
			{ "matching" => {
				"matching-custom-matcher" => $matching_custom_matcher,
				"matching-pattern" => $matching_pattern, #TODO: reuse
				"having-files" => $having_files
			}
		});

	my $filter = op("filter", \&Disketo_Instructions::filter, [], [], 
			"Filters by given criteria",
			{ "what" => {
				"files" => $filter_files,
				"dirs" => $filter_dirs
			}
		});

	# -- print primitive operations ----------------------------------
	
	my $print_simply = op("print-simply", \&Disketo_Instructions::print_simply, [], [], 
			"Prints each resource by its complete path.",
			{}
		);
		
	my $print_only_name = op("print-only-name", \&Disketo_Instructions::print_only_name, [], [], 
			"Prints only the name of the resource.",
			{}
		);
	
	my $print_custom = op("print-custom", \&Disketo_Instructions::print_custom, [], [], 
			"Prints each resource by the given function.",
			{ "printer" => undef }
		);
		
	# -- print composite operations ---------------------------------
	
	my $print_files = op("print_files", \&Disketo_Instructions::print_files, [], [],
		"Prints files.",
		{ "how" => {
			"simply" => $print_simply,
			"only-name" => $print_only_name,
			"custom" => $print_custom }
		});
				
	my $print_dirs = op("print_files", \&Disketo_Instructions::print_dirs, [], [],
		"Prints dirs.",
		{ "how" => {
			"simply" => $print_simply, #TODO reuse from print_files
			"only-name" => $print_only_name,
			"custom" => $print_custom }
		});
	
	my $print = op("print", \&Disketo_Instructions::print, [], [], 
		"Prints given.",
		{ "what" => {
			"files" => $print_files,
			"dirs" => $print_dirs }
		});

	
	# -- x primitive operations ---------------------------------
	# -- x composite operations ---------------------------------


	# -- all together -------------------------------------------------

	my %commands = (
		"compute" => $compute,
		"filter" => $filter,
		"print" => $print
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

	} elsif ($params ~~ $prepending_params) {
		$prepending_arguments = $arguments;

	#TODO arguments := if $prepending_instruction takes XYZ, then pick from $instruction

	} else {
		print(Dumper($prepending_command, $command));
		die("Unimplemented prepend of " . $prepending_command->{"name"} . " before " . $command->{"name"});
	}
	
	return {"command" => $prepending_command, "arguments" => $prepending_arguments };
}

