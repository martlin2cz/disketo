#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

package Disketo_Evaluator;
my $VERSION=0.1;

use Data::Dumper;
use Disketo_Utils;
use Disketo_Extras;

#######################################
#######################################


sub run($@) {
	my $script = shift @_;
	my @params = @_;

	my $parsed_ref = parse($script);
	my $program_ref = validate($parsed_ref, \@params);
	#TODO if --dry-run print else
	#TODO if no such params, print usage
	evaluate($program_ref);
}

#######################################

sub parse($$) {
	my ($script_file, $program_args_ref) = (@_);
	
	my $content = load_file($script_file);
	my $parsed_ref = parse_content($content);
	my ($program_ref, $program_args_mod_ref) = validate($parsed_ref, $program_args_ref);

	return ($program_ref, $program_args_mod_ref);
}

sub load_file($) {
	my ($file) = @_;
	
	my $result = "";
	
	open(F, "<$file") or die("Cannot open script file $file): " . $!);
	while (<F>) {
    $result = $result . $_;
	}
	close (F);

	return $result;
}

#######################################

sub parse_content($) {
	my ($content) = @_;

	my @tokens = tokenize($content);
	my @result = ([]);
	for my $token (@tokens) {
		if ($token =~ /^#/) {
			next;
		}
		elsif ($token eq "\n") {
			if (scalar @{ @result[-1] } > 0) { #if previous line wasn't empty
				push @result, [];
			}
		} 
		else {
			push @{ @result[-1] }, $token;
		}
	}

	if (scalar @{ @result[-1] } == 0) { 
		pop @result;
	}

	return \@result;
}

sub tokenize($) {
	my ($content) = @_;

	my @parts = $content =~ / 
		(?# wrapped in curly backets, to use subs)
		(\{ (?: [^{}]* | (?0) )* \} ) | 
		(?# wrapped in double-quotes)
		(\" [^\"]* \") | 
		(?# regular text)
		( [\w]+ ) | 
		(?# the $$ marker)
		( \$\$ ) | 
		(?# pass newlines too)
		( \n ) |
		(?# comments)
		(\# [^\n]* \n) /gx;
		
	my @filtered = grep /(.+)|(\n)/, @parts;
	my @collapsed = collapse_subs(@filtered);

	return @collapsed;
}

sub collapse_subs(@) {
	my @tokens = @_;
	my @result = ();

	for (my $i = 0; $i < scalar @tokens; $i++) {
		my $token = @tokens[$i];
		if ($token eq "sub") {
			$i++;
			$token = @tokens[$i];
			$token = "sub " . $token;
		}
		push @result, $token;
	}

	return @result;
}

#######################################

sub validate($$) {
	my ($parsed_ref, $program_args_ref) = @_;

	my $functions_ref = functions_table();
	my @program = ();

	for my $statement_ref (@{ $parsed_ref }) {
		my ($statement_mod_ref, $fnname, $function_ref) = validate_function($statement_ref, $functions_ref);
		
		my $resolved_args_ref;
		($resolved_args_ref, $program_args_ref) = validate_params($statement_mod_ref, $program_args_ref, $fnname, $function_ref);

		my %instruction = ( "function" => $function_ref, "arguments" => $resolved_args_ref );
		push @program, \%instruction;
	}

	return (\@program, $program_args_ref);

	#TODO for each line:
	#TODO  check whether the function exists
	#TODO  check whether requires loaded roots/stats
	#TODO  check argc in both terms (@ARGV and caller/callee match)
	#TODO  evaluate args?
	#TODO  extract @ARGV values, put into instead of $$s
}

sub validate_function($$) {
	my ($statement_ref, $functions_ref) = @_;

	my @statement = @{ $statement_ref };
	my $fnname = shift @statement;

	my $function_ref = %{ $functions_ref }{$fnname};
	if (!$function_ref) {
		die("Unknown command $fnname");
	}

	return (\@statement, $fnname, $function_ref);
}

sub validate_params($$$$) {
	my ($statement_ref, $program_args_ref, $fnname, $function_ref) = @_;
	my @program_args = @{ $program_args_ref };
	my %function = %{ $function_ref };
	my @params = @{ $function{"params"} };
	my @arguments = @{ $statement_ref };

	if ((scalar @params) ne (scalar @arguments)) {
		die("$fnname expects " . (scalar @params) . " params (" . join(", ", @params) . "), "
				. "given " . (scalar @arguments) . "(". join(", ", @arguments) . ")");
	}

	my @resolved_args = ();
	for my $arg (@arguments) {
		if ($arg eq '$$') {
			if (scalar @program_args == 0) {
				die("No such arguments at $fnname");
			}
			$arg = shift @program_args;
			push @resolved_args, $arg;
		}
		elsif ($arg =~ /^sub ?\{/) {
			my $fn = eval($arg);
			push @resolved_args, $fn;
		}
		else {
			push @resolved_args, $arg;
		}
	}

	return (\@resolved_args, \@program_args);
}

#######################################


sub print() {
	#TODO for each line:
	#TODO  print it somehow
}

sub evaluate() {
	#TODO for each line:
	#TODO  evaluate it somehow
}

#######################################

sub functions_table() {
	my %table = (
		"list_all_directories" => { "name" => "list_all_directories", 
			"requires_list" => 0, "requires_stats" => 0, "params" => [""]},
		"load_stats" => { "name" => "load_stats", 
			"requires_list" => 1, "requires_stats" => 0, "params" => [""]},
		"filter_directories_custom" => { "name" => "filter_directories_custom", 
			"requires_list" => 1, "requires_stats" => 0, "params" => ["predicate"]},
		"filter_directories_by_pattern" => { "name" => "filter_directories_by_pattern", 
			"requires_list" => 1, "requires_stats" => 0, "params" => ["pattern"]},
		"filter_directories_by_files_pattern" => { "name" => "filter_directories_by_files_pattern", 
			"requires_list" => 1, "requires_stats" => 0, "params" => ["pattern", "threshold"]},
		"filter_directories_matching" => { "name" => "filter_directories_matching", 
			"requires_list" => 1, "requires_stats" => 0, "params" => ["matcher"]},
		"filter_directories_of_same_name" => { "name" => "filter_directories_of_same_name", 
			"requires_list" => 1, "requires_stats" => 0, "params" => []},
		"filter_directories_with_common_files" => { "name" => "filter_directories_with_common_files", 
			"requires_list" => 1, "requires_stats" => 0, "params" => ["min_count", "files_matcher"]},
		"filter_directories_with_common_file_names" => { "name" => "filter_directories_with_common_file_names", 
			"requires_list" => 1, "requires_stats" => 0, "params" => ["min_coun"]},
		"filter_directories_with_common_file_names_with_size" => { "name" => "filter_directories_with_common_file_names_with_size", 
			"requires_list" => 1, "requires_stats" => 1, "params" => ["min_count"]},
		"print_directories_simply" => { "name" => "print_directories_simply", 
			"requires_list" => 1, "requires_stats" => 0, "params" => []},
		"print_directories" => { "name" => "print_directories", 
			"requires_list" => 1, "requires_stats" => 0, "params" => ["printer"]},
		"print_files" => { "name" => "print_files", 
			"requires_list" => 1, "requires_stats" => 0, "params" => ["printer"]}
		#		"" => { "name" => "", 
		#	"requires_list" => 1, "requires_stats" => 1, "params" => [""]},
	);

	return \%table;
}
