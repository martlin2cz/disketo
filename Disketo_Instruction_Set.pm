#!/usr/bin/perl
use strict;

package Disketo_Instruction_Set; 
my $VERSION=2.0.0;
  
use Disketo_Instructions;
use Switch;
use Data::Dumper;

  
########################################################################
# The instruction set. Creates the mapping between the disketo script
# statements and particular perl functions.
########################################################################

sub commands() {
	my %table = (
		# instructions generated by ./generate-instructions-set-module.sh
  
		# --- load    -----------------------
		'load' => { 
			'name' => 'load', 
			'method' => \&Disketo_Instructions::load, 
			'requires' => [], 
			'produces' => undef, 
			'params' => [], 
			'doc' => 'Loads the resources from the filesystem(s)' 
		}, 
		  
		# --- context_stats    -----------------------
		'context_stats' => { 
			'name' => 'context_stats', 
			'method' => \&Disketo_Instructions::context_stats, 
			'requires' => [], 
			'produces' => undef, 
			'params' => [], 
			'doc' => 'Prints the informations about the current context' 
		}, 
		  
		# --- count_files    -----------------------
		'count_files' => { 
			'name' => 'count_files', 
			'method' => \&Disketo_Instructions::count_files, 
			'requires' => [], 
			'produces' => 'files count', 
			'params' => [], 
			'doc' => 'Computes the counts of the files in each dir' 
		}, 
		  
		# --- compute_custom_for_each_dir   meta_name, computer -----------------------
		'compute_custom_for_each_dir' => { 
			'name' => 'compute_custom_for_each_dir', 
			'method' => \&Disketo_Instructions::compute_custom_for_each_dir, 
			'requires' => [], 
			'produces' => undef, 
			'params' => ['meta_name', 'computer', ], 
			'doc' => 'Computes given computer on each dir to produce the given meta' 
		}, 
		  
		# --- compute_custom_for_each_file   meta_name, computer -----------------------
		'compute_custom_for_each_file' => { 
			'name' => 'compute_custom_for_each_file', 
			'method' => \&Disketo_Instructions::compute_custom_for_each_file, 
			'requires' => [], 
			'produces' => undef, 
			'params' => ['meta_name', 'computer', ], 
			'doc' => 'Computes given computer on each file to produce the given meta' 
		}, 
		  
		# --- compute_files_matching_pattern   pattern -----------------------
		'compute_files_matching_pattern' => { 
			'name' => 'compute_files_matching_pattern', 
			'method' => \&Disketo_Instructions::compute_files_matching_pattern, 
			'requires' => [], 
			'produces' => 'files matching', 
			'params' => ['pattern', ], 
			'doc' => 'Computes meta with files matching given pattern' 
		}, 
		  
		# --- compute_files_matching_custom   matcher -----------------------
		'compute_files_matching_custom' => { 
			'name' => 'compute_files_matching_custom', 
			'method' => \&Disketo_Instructions::compute_files_matching_custom, 
			'requires' => [], 
			'produces' => 'files matching', 
			'params' => ['matcher', ], 
			'doc' => 'Computes meta with files matching given matcher' 
		}, 
		  
		# --- compute_dirs_matching_pattern   pattern -----------------------
		'compute_dirs_matching_pattern' => { 
			'name' => 'compute_dirs_matching_pattern', 
			'method' => \&Disketo_Instructions::compute_dirs_matching_pattern, 
			'requires' => [], 
			'produces' => 'dirs matching', 
			'params' => ['pattern', ], 
			'doc' => 'Computes meta with dirs matching given pattern' 
		}, 
		  
		# --- compute_dirs_matching_custom   matcher -----------------------
		'compute_dirs_matching_custom' => { 
			'name' => 'compute_dirs_matching_custom', 
			'method' => \&Disketo_Instructions::compute_dirs_matching_custom, 
			'requires' => [], 
			'produces' => 'dirs matching', 
			'params' => ['matcher', ], 
			'doc' => 'Computes meta with dirs matching given matcher' 
		}, 
		  
		# --- compute_files_of_dir_matching_pattern   pattern -----------------------
		'compute_files_of_dir_matching_pattern' => { 
			'name' => 'compute_files_of_dir_matching_pattern', 
			'method' => \&Disketo_Instructions::compute_files_of_dir_matching_pattern, 
			'requires' => [], 
			'produces' => 'files matching', 
			'params' => ['pattern', ], 
			'doc' => 'Computes meta with files of each dir matching given pattern' 
		}, 
		  
		# --- compute_files_of_dir_matching_custom   matcher -----------------------
		'compute_files_of_dir_matching_custom' => { 
			'name' => 'compute_files_of_dir_matching_custom', 
			'method' => \&Disketo_Instructions::compute_files_of_dir_matching_custom, 
			'requires' => [], 
			'produces' => 'files matching', 
			'params' => ['matcher', ], 
			'doc' => 'Computes meta with files of each dir matching given matcher' 
		}, 
		  
		# --- group_files_by_names    -----------------------
		'group_files_by_names' => { 
			'name' => 'group_files_by_names', 
			'method' => \&Disketo_Instructions::group_files_by_names, 
			'requires' => [], 
			'produces' => 'files names', 
			'params' => [], 
			'doc' => 'Groups files by names' 
		}, 
		  
		# --- group_files_by_custom   groupper, meta_name -----------------------
		'group_files_by_custom' => { 
			'name' => 'group_files_by_custom', 
			'method' => \&Disketo_Instructions::group_files_by_custom, 
			'requires' => [], 
			'produces' => undef, 
			'params' => ['groupper', 'meta_name', ], 
			'doc' => 'Groups files by custom groupper' 
		}, 
		  
		# --- group_dirs_by_names    -----------------------
		'group_dirs_by_names' => { 
			'name' => 'group_dirs_by_names', 
			'method' => \&Disketo_Instructions::group_dirs_by_names, 
			'requires' => [], 
			'produces' => 'dirs names', 
			'params' => [], 
			'doc' => 'Groups dirs by names' 
		}, 
		  
		# --- group_dirs_by_custom   groupper, meta_name -----------------------
		'group_dirs_by_custom' => { 
			'name' => 'group_dirs_by_custom', 
			'method' => \&Disketo_Instructions::group_dirs_by_custom, 
			'requires' => [], 
			'produces' => undef, 
			'params' => ['groupper', 'meta_name', ], 
			'doc' => 'Groups dirs by custom groupper' 
		}, 
		  
		# --- filter_dirs_matching_pattern   pattern -----------------------
		'filter_dirs_matching_pattern' => { 
			'name' => 'filter_dirs_matching_pattern', 
			'method' => \&Disketo_Instructions::filter_dirs_matching_pattern, 
			'requires' => [], 
			'produces' => undef, 
			'params' => ['pattern', ], 
			'doc' => 'Filters dirs matching given pattern' 
		}, 
		  
		# --- filter_dirs_matching_custom   predicate -----------------------
		'filter_dirs_matching_custom' => { 
			'name' => 'filter_dirs_matching_custom', 
			'method' => \&Disketo_Instructions::filter_dirs_matching_custom, 
			'requires' => [], 
			'produces' => undef, 
			'params' => ['predicate', ], 
			'doc' => 'Filters dirs matching given predicate' 
		}, 
		  
		# --- filter_dirs_by_meta   meta_name -----------------------
		'filter_dirs_by_meta' => { 
			'name' => 'filter_dirs_by_meta', 
			'method' => \&Disketo_Instructions::filter_dirs_by_meta, 
			'requires' => [], 
			'produces' => undef, 
			'params' => ['meta_name', ], 
			'doc' => 'Filters dirs matching given meta' 
		}, 
		  
		# --- filter_files_matching_pattern   pattern -----------------------
		'filter_files_matching_pattern' => { 
			'name' => 'filter_files_matching_pattern', 
			'method' => \&Disketo_Instructions::filter_files_matching_pattern, 
			'requires' => [], 
			'produces' => undef, 
			'params' => ['pattern', ], 
			'doc' => 'Filters files matching given pattern' 
		}, 
		  
		# --- filter_files_matching_custom   predicate -----------------------
		'filter_files_matching_custom' => { 
			'name' => 'filter_files_matching_custom', 
			'method' => \&Disketo_Instructions::filter_files_matching_custom, 
			'requires' => [], 
			'produces' => undef, 
			'params' => ['predicate', ], 
			'doc' => 'Filters files matching given predicate' 
		}, 
		  
		# --- filter_files_by_meta   meta_name -----------------------
		'filter_files_by_meta' => { 
			'name' => 'filter_files_by_meta', 
			'method' => \&Disketo_Instructions::filter_files_by_meta, 
			'requires' => [], 
			'produces' => undef, 
			'params' => ['meta_name', ], 
			'doc' => 'Filters files matching given meta' 
		}, 
		  
		# --- filter_dirs_with_files_matching_pattern   files_pattern,min_count -----------------------
		'filter_dirs_with_files_matching_pattern' => { 
			'name' => 'filter_dirs_with_files_matching_pattern', 
			'method' => \&Disketo_Instructions::filter_dirs_with_files_matching_pattern, 
			'requires' => [], 
			'produces' => undef, 
			'params' => ['files_pattern', 'min_count', ], 
			'doc' => 'Filters dirs with having at least given number of files matching given pattern' 
		}, 
		  
		# --- filter_dirs_with_files_matching_custom   files_predicate,min_count -----------------------
		'filter_dirs_with_files_matching_custom' => { 
			'name' => 'filter_dirs_with_files_matching_custom', 
			'method' => \&Disketo_Instructions::filter_dirs_with_files_matching_custom, 
			'requires' => [], 
			'produces' => undef, 
			'params' => ['files_predicate', 'min_count', ], 
			'doc' => 'Filters dirs with having at least given number of files matching given predicate' 
		}, 
		  
		# --- filter_dirs_with_files_matching_meta   files_meta_name,min_count -----------------------
		'filter_dirs_with_files_matching_meta' => { 
			'name' => 'filter_dirs_with_files_matching_meta', 
			'method' => \&Disketo_Instructions::filter_dirs_with_files_matching_meta, 
			'requires' => [], 
			'produces' => undef, 
			'params' => ['files_meta_name', 'min_count', ], 
			'doc' => 'Filters dirs with having at least given number of files matching given meta' 
		}, 
		  
		# --- filter_duplicate_dirs_by_name    -----------------------
		'filter_duplicate_dirs_by_name' => { 
			'name' => 'filter_duplicate_dirs_by_name', 
			'method' => \&Disketo_Instructions::filter_duplicate_dirs_by_name, 
			'requires' => ['dirs names', ], 
			'produces' => undef, 
			'params' => [], 
			'doc' => 'Filters duplicate dirs by name' 
		}, 
		  
		# --- filter_duplicate_files_by_name    -----------------------
		'filter_duplicate_files_by_name' => { 
			'name' => 'filter_duplicate_files_by_name', 
			'method' => \&Disketo_Instructions::filter_duplicate_files_by_name, 
			'requires' => ['files names', ], 
			'produces' => undef, 
			'params' => [], 
			'doc' => 'Filters duplicate files by name' 
		}, 
		  
		# --- filter_duplicate_dirs_by_custom_groupper   groupper, meta_name -----------------------
		'filter_duplicate_dirs_by_custom_groupper' => { 
			'name' => 'filter_duplicate_dirs_by_custom_groupper', 
			'method' => \&Disketo_Instructions::filter_duplicate_dirs_by_custom_groupper, 
			'requires' => [], 
			'produces' => undef, 
			'params' => ['groupper', 'meta_name', ], 
			'doc' => 'Filters duplicate dirs by given groupper' 
		}, 
		  
		# --- filter_duplicate_files_by_custom_groupper   groupper, meta_name -----------------------
		'filter_duplicate_files_by_custom_groupper' => { 
			'name' => 'filter_duplicate_files_by_custom_groupper', 
			'method' => \&Disketo_Instructions::filter_duplicate_files_by_custom_groupper, 
			'requires' => [], 
			'produces' => undef, 
			'params' => ['groupper', 'meta_name', ], 
			'doc' => 'Filters duplicate files by given groupper' 
		}, 
		  
		# --- filter_duplicate_dirs_with_common_files_by_name    -----------------------
		'filter_duplicate_dirs_with_common_files_by_name' => { 
			'name' => 'filter_duplicate_dirs_with_common_files_by_name', 
			'method' => \&Disketo_Instructions::filter_duplicate_dirs_with_common_files_by_name, 
			'requires' => ['files names', ], 
			'produces' => undef, 
			'params' => [], 
			'doc' => 'Filters duplicate dirs with common files by their name' 
		}, 
		  
		# --- filter_duplicate_dirs_with_common_files_by_custom_groupper   groupper, meta_name -----------------------
		'filter_duplicate_dirs_with_common_files_by_custom_groupper' => { 
			'name' => 'filter_duplicate_dirs_with_common_files_by_custom_groupper', 
			'method' => \&Disketo_Instructions::filter_duplicate_dirs_with_common_files_by_custom_groupper, 
			'requires' => [], 
			'produces' => undef, 
			'params' => ['groupper', 'meta_name', ], 
			'doc' => 'Filters duplicate dirs with common files by their custom groupper' 
		}, 
		  
		# --- filter_duplicate_dirs_by_custom_comparer   comparer -----------------------
		'filter_duplicate_dirs_by_custom_comparer' => { 
			'name' => 'filter_duplicate_dirs_by_custom_comparer', 
			'method' => \&Disketo_Instructions::filter_duplicate_dirs_by_custom_comparer, 
			'requires' => [], 
			'produces' => undef, 
			'params' => ['comparer', ], 
			'doc' => 'Filters duplicate dirs by custom comparer' 
		}, 
		  
		# --- filter_duplicate_files_by_custom_comparer   comparer -----------------------
		'filter_duplicate_files_by_custom_comparer' => { 
			'name' => 'filter_duplicate_files_by_custom_comparer', 
			'method' => \&Disketo_Instructions::filter_duplicate_files_by_custom_comparer, 
			'requires' => [], 
			'produces' => undef, 
			'params' => ['comparer', ], 
			'doc' => 'Filters duplicate files by custom comparer' 
		}, 
		  
		# --- filter_duplicate_dirs_with_common_files_by_custom_comparer   files_comparer -----------------------
		'filter_duplicate_dirs_with_common_files_by_custom_comparer' => { 
			'name' => 'filter_duplicate_dirs_with_common_files_by_custom_comparer', 
			'method' => \&Disketo_Instructions::filter_duplicate_dirs_with_common_files_by_custom_comparer, 
			'requires' => [], 
			'produces' => undef, 
			'params' => ['files_comparer', ], 
			'doc' => 'Filters duplicate dirs with common files by custom comparer' 
		}, 
		  
		# --- print_dirs_simply    -----------------------
		'print_dirs_simply' => { 
			'name' => 'print_dirs_simply', 
			'method' => \&Disketo_Instructions::print_dirs_simply, 
			'requires' => [], 
			'produces' => undef, 
			'params' => [], 
			'doc' => 'Prints dirs simply' 
		}, 
		  
		# --- print_dirs_custom   printer -----------------------
		'print_dirs_custom' => { 
			'name' => 'print_dirs_custom', 
			'method' => \&Disketo_Instructions::print_dirs_custom, 
			'requires' => [], 
			'produces' => undef, 
			'params' => ['printer', ], 
			'doc' => 'Prints dirs by custom printer' 
		}, 
		  
		# --- print_files_simply    -----------------------
		'print_files_simply' => { 
			'name' => 'print_files_simply', 
			'method' => \&Disketo_Instructions::print_files_simply, 
			'requires' => [], 
			'produces' => undef, 
			'params' => [], 
			'doc' => 'Prints files simply' 
		}, 
		  
		# --- print_files_custom   printer -----------------------
		'print_files_custom' => { 
			'name' => 'print_files_custom', 
			'method' => \&Disketo_Instructions::print_files_custom, 
			'requires' => [], 
			'produces' => undef, 
			'params' => ['printer', ], 
			'doc' => 'Prints files by custom printer' 
		}, 
		
	);
	
	return \%table;
}

sub prepending_instruction($$) {
	my ($instruction, $prepending_command) = @_;
	 
	my $command = $instruction->{"command"};
	my $arguments = $instruction->{"arguments"};
	
	my $params = $command->{"params"};
	my $prepending_params = $prepending_command->{"params"};
	
	my $prepending_arguments; 
	if ($params ~~ $prepending_params) {
		$prepending_arguments = $arguments;
	#TODO arguments := if $prepending_instruction takes XYZ, then pick from $instruction
	} else {
		print(Dumper($prepending_command, $command));
		die("Unimplemented prepend of " . $prepending_command->{"name"} . " before " . $command->{"name"});
	}
	
	return {"command" => $prepending_command, "arguments" => $prepending_arguments };
}
