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


sub run(@) {
	my $dry_run = 0;
	if ((scalar @_ > 0) and ((@_[0] eq "--dry") or (@_[0] eq "--dry-run"))) {
		$dry_run = 1;
		shift @_;
	}

	my $script = shift @_;
	my @args = @_;

	my ($program_ref, $params_ref) = parse($script);
	
	if (scalar @{ $params_ref } >= scalar @args) {
		print_usage($script, $params_ref, \@args);
	} else {
		if ($dry_run) {
			printit($program_ref, \@args);
		} else {
			evaluate($program_ref, \@args);
		}
	}
}

#######################################

sub parse($) {
	my ($script_file) = @_;
	
	my $content = load_file($script_file);
	my $parsed_ref = parse_content($content);
	my ($program_ref, $parameters_ref) = validate($parsed_ref);

	return ($program_ref, $parameters_ref);
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

sub validate($) {
	my ($parsed_ref) = @_;

	my $functions_ref = functions_table();
	my @program = ();
	my @parameters = ();

	for my $statement_ref (@{ $parsed_ref }) {
		my ($statement_mod_ref, $fnname, $function_ref) = validate_function($statement_ref, $functions_ref);
		
		my ($resolved_args_ref, $sub_params_ref);
		($resolved_args_ref, $sub_params_ref) = validate_params($statement_mod_ref, $fnname, $function_ref);

		my %instruction = ( "function" => $function_ref, "arguments" => $resolved_args_ref );
		push @program, \%instruction;

		@parameters = (@parameters, @{ $sub_params_ref });
	}

	return (\@program, \@parameters);
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

sub validate_params($$$) {
	my ($statement_ref, $fnname, $function_ref) = @_;
	my %function = %{ $function_ref };
	my @params = @{ $function{"params"} };
	my @arguments = @{ $statement_ref };
	my @statement_params = ();

	if ((scalar @params) ne (scalar @arguments)) {
		die("$fnname expects " . (scalar @params) . " params (" . join(", ", @params) . "), "
				. "given " . (scalar @arguments) . "(". join(", ", @arguments) . ")");
	}

	my $index = 0;
	for my $arg (@arguments) {
		if ($arg eq '$$') {
			my $param_name = $params[$index];
			my %param = ("name" => $param_name, "function" => $function_ref);
			push @statement_params, \%param;
		}
		elsif ($arg =~ /^sub ?\{/) {
			my $fn = eval($arg);
			@arguments[$index] = $fn;
		}
		else {
			##okay, cmon
		}

		$index++;
	}

	return (\@arguments, \@statement_params);
}

#######################################

sub print_usage($$$) {
	my ($script_name, $params_ref, $args_ref) = @_;
	my @params = @{ $params_ref };
	
	my $usage = $script_name . " " . 
		join(" ", 
			map({
				my $param_ref = $_;
				my %param = %{ $param_ref };
				my $param_name = %param{"name"};
				my $param_function = %{ %param{"function"} }{"name"};
				
				"<$param_name of $param_function>";
			} @params)) . " <DIRECTORIES...>";
	
	print STDERR "Expected " . (scalar @params) . " arguments, given " . (scalar @{ $args_ref }) . "\n";
	Disketo_Utils::usage([], $usage);
}

sub printit($$) {
	my ($program_ref, $program_args_ref) = @_;
	my @program_args = @{ $program_args_ref };

	for my $instruction (@{ $program_ref }) {
		my $function_name = $instruction->{"function"}->{"name"};
		my $params_ref = $instruction->{"function"}->{"params"};
		my $args_ref = $instruction->{"arguments"};
	
		print STDERR "Will invoke $function_name:\n";
		my $index;

		my @params = @{ $params_ref };
		my @args = @{ $args_ref };
		for ($index = 0; $index < scalar @params; $index++) {
			my $param = $params[$index];
			my $arg = $args[$index];

			if ($arg eq "\$\$") {
				my $value = shift @program_args;
				print STDERR "\t$param := $arg, which is currently $value\n";
			} else {
				print STDERR "\t$param := $arg\n";
			}
		}
	}
	
	print STDERR "The remaining arguments (" . join(", ", @program_args) . ") will be used as a list of directories\n";
}


sub evaluate() {
	my ($program_ref, $program_args_ref) = @_;
	my ($use_args_ref, $dirs_to_list) = extract_dirs_to_list($program_ref, $program_args_ref);
	
	my ($dirs_ref, $stats_ref) = (undef, undef);
	for my $instruction (@{ $program_ref }) {
		my $function_name = $instruction->{"function"}->{"method"};
		my $requires_dirs = $instruction->{"function"}->{"requires_dirs"};
		my $requires_stats = $instruction->{"function"}->{"requires_dirs"};
		
		if ($requires_dirs and is_undef($dirs_ref)) {
			my %dirs = Disketo_Extra::load_dirs(	); #FOOOO
			$dirs_ref = \%dirs;
		}
		if ($requires_stats and is_undef($stats_ref)) {
			my %stats = Disketo_Extra::load_stats(	); #FOOOO
			$dirs_ref = \%stats;
		}
		my $args_ref = $instruction->{"arguments"};

		for my $arg (@{ $args_ref }) {
			if ($arg eq "\$\$") {
				my $value = shift @{ $use_args_ref }; #FIXME make it @var
				#TODO use the value
			} else {
				#TODO use the value
			}
		}
		#TODO invoke the method
	}
	
	#TODO for each line:
	#TODO  evaluate it somehow
}

sub extract_dirs_to_list($$) {
	my ($program_ref, $program_args_ref) = @_;
	my @program_args = @{ $program_args_ref };
	my @use_args = ();

	for my $instruction (@{ $program_ref }) {
		my $args_ref = $instruction->{"arguments"};
		for my $arg (@{ $args_ref }) {

			if ($arg eq "\$\$") {
				my $value = shift @program_args;
				push @use_args, $value;
			}
		}
	}
	
	return (\@use_args, \@program_args);
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
