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

# Runs the interpreation
# input: boolean flag dry_run, script file name, reference to array of arguments
sub run($$$) {
	my ($dry_run, $script, $args_ref) = @_;
	
	my ($program_ref) = parse($script);
	my $params_count = count_params($program_ref);
	
	if (scalar @{ $args_ref } < $params_count + 1) {
		print_usage($script, $program_ref, $args_ref);
	} else {
		my $prepared_ref = prepare($program_ref, $args_ref);	
		if ($dry_run) {
			print_program($prepared_ref, $args_ref);
		} else {
			run_program($prepared_ref, $args_ref);
		}
	}
}

#######################################

# Parses given file
sub parse($) {
	my ($script_file) = @_;
	
	my $content = load_file($script_file);
	my $parsed_ref = parse_content($content);
	my $program_ref = validate($parsed_ref);

	return $program_ref;
}

# Loads contents of given file into string
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

# Parses given content into "statements"
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

# Tokenizes given input string to tokens
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
	my @cleaned = map { $_ =~ s/^\"([^\"]*)\"$/\1/r } @filtered;
	my @collapsed = collapse_subs(@cleaned);

	return @collapsed;
}

# All pairs of tokens "sub" and "{ ... }" joins them into one token.
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

# Runs the validation, in fuckt semantic analysis (converts "statements" into "program")
sub validate($) {
	my ($parsed_ref) = @_;

	my $functions_ref = functions_table();
	my @program = ();

	for my $statement_ref (@{ $parsed_ref }) {
		my ($statement_mod_ref, $fnname, $function_ref) = validate_function($statement_ref, $functions_ref);
		
		my $resolved_args_ref = validate_params($statement_mod_ref, $fnname, $function_ref);

		my %instruction = ( "function" => $function_ref, "arguments" => $resolved_args_ref );
		push @program, \%instruction;
	}

	return \@program;
}

# Validates given function (checks her existence agains given functions table)
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

# Validates params of given function (checks the number of them)
sub validate_params($$$) {
	my ($statement_ref, $fnname, $function_ref) = @_;
	my %function = %{ $function_ref };
	my @params = @{ $function{"params"} };
	my @arguments = @{ $statement_ref };

	if ((scalar @params) ne (scalar @arguments)) {
		die("$fnname expects " . (scalar @params) . " params (" . join(", ", @params) . "), "
				. "given " . (scalar @arguments) . " (". join(", ", @arguments) . ")");
	}

	return \@arguments;
}

#######################################

# Prints usage of the app with script specified
sub print_usage($$$) {
	my ($script_name, $program_ref, $program_args_ref) = @_;
	my @args = @{ $program_args_ref };
	
	my $usage = "$script_name ";
	my $count = 0;
	walk_program($program_ref, sub {
		my ($instruction_ref,$function_name,$function_method,$requires_list,$requires_stats,$params_ref,$args_ref)	= @_;

		for (my $i = 0; $i < scalar @{ $params_ref }; $i++) {
			my $param = $params_ref->[$i];
			my $arg = $args_ref->[$i];

			if ($arg eq "\$\$") {
				$usage = $usage . "<$param of $function_name> ";
				$count++;
			}
		}
	});
	$usage = $usage . "<DIRECTORY...>";
	
	print STDERR "Expected $count arguments, given " . (scalar @{ $program_args_ref }) . "\n";
	Disketo_Utils::usage([], $usage);
}

# Goes throught given program and counts number of "$$" occurences
sub count_params($) {
	my ($program_ref) = @_;

	my $count = 0;
	walk_program($program_ref, sub {
		my ($instruction_ref,$function_name,$function_method,$requires_list,$requires_stats,$params_ref,$args_ref)	= @_;

		for my $arg (@{ $args_ref }) {
			if ($arg eq "\$\$") {
				$count++;
			}
		}
	});

	return $count;
}


#######################################

# Prepares the program to print/execute (inserts load_* instructions where needed)
sub prepare($$) {
	my ($program_ref, $program_args_ref) = @_;

	$program_ref = insert_loads($program_ref);
	
	return $program_ref;
}

# Inserts load_* instructions where needed
sub insert_loads($) {
	my ($program_ref) = @_;
	
	my $functions_ref = functions_table();
	
	my @program_mod = ();
	my $listed = 0;
	my $stats_loaded = 0;

	walk_program($program_ref, sub {
		my ($instruction_ref,$function_name,$function_method,$requires_list,$requires_stats,$params_ref,$args_ref)	= @_;

		if ($function_name eq "list_all_directories") {
			$listed = 1;
		}
		if ($function_name eq "load_stats") {
			$stats_loaded = 1;
		}
		
		if ($requires_list and not $listed) {
			my $list_function = $functions_ref->{"list_all_directories"};
			my %list_instruction = ("function" => $list_function, "arguments" => []);
			push @program_mod, \%list_instruction;
			$listed = 1;
		}
		if ($requires_stats and not $stats_loaded) {
			my $stats_function = $functions_ref->{"load_stats"};
			my %stats_instruction = ("function" => $stats_function, "arguments" => []);
			push @program_mod, \%stats_instruction;
			$stats_loaded = 1;
		}

		push @program_mod, $instruction_ref;
	});

	return \@program_mod;
}


#######################################

# Prints the program (with arguments)
sub print_program($$) {
	my ($program_ref, $program_args_ref) = @_;
	my @program_args = @{ $program_args_ref };

	my ($use_args_ref, $dirs_to_list) = extract_dirs_to_list($program_ref, $program_args_ref);	
	my @args_to_use = @{ $use_args_ref };

	walk_program($program_ref, sub {
		my ($instruction_ref,$function_name,$function_method,$requires_list,$requires_stats,$params_ref,$args_ref) = @_;

		print STDERR "Will invoke $function_name:\n";
		if ($function_name eq "list_all_directories") {
			print STDERR "\t with directories " . join(", ", @{ $dirs_to_list }) . "\n";
		} else {
			my $index;

			my @params = @{ $params_ref };
			my @args = @{ $args_ref };
			for ($index = 0; $index < scalar @params; $index++) {
				my $param = $params[$index];
				my $arg = $args[$index];

				if ($arg eq "\$\$") {
					my $value = shift @args_to_use;
					print STDERR "\t$param := $arg, which is currently $value\n";
				} else {
					print STDERR "\t$param := $arg\n";
					if ($arg =~ "sub ?\{") {
						eval($arg);
						if ($@) {
							print STDERR "\tWarning, previous function contains syntax error: $@\n";
						}
					}
				}
			}
		}
	});
}

# Runs the given program. What else?
sub run_program($$) {
	my ($program_ref, $program_args_ref) = @_;
	
	my ($use_args_ref, $dirs_to_list) = extract_dirs_to_list($program_ref, $program_args_ref);
	my @use_args = @{ $use_args_ref };

	my ($dirs_ref, $stats_ref, $previous_ref) = (undef, undef);
	
	walk_program($program_ref, sub {
		my ($instruction_ref,$function_name,$function_method,$requires_list,$requires_stats,$params_ref,$args_ref) = @_;
		
		my $arguments_ref;
		($arguments_ref, $use_args_ref) = prepare_arguments(
			$function_name, $requires_list, $requires_stats, $dirs_ref, $stats_ref, $previous_ref, $args_ref, $use_args_ref, $dirs_to_list);
		my @arguments = @{ $arguments_ref };
		
		#print "Will invoke $function_name with " . join(", ", @arguments) . "...\n";
		my @result = $function_method->(@arguments);
		
		$previous_ref = \@result;
		$dirs_ref = @result[0];
		if ($function_name eq "load_stats") {
			$stats_ref = @result[1];
		}
	});
}

sub prepare_arguments($) {
	my ($function_name,$requires_list,$requires_stats,$dirs_ref,$stats_ref,$previous_ref,$args_ref,$use_args_ref,$dirs_to_list) = @_;

	my @use_args = @{ $use_args_ref };

	my @arguments;
	if ($function_name ne "list_all_directories") {
		@arguments = @{ $args_ref };
		@arguments = map {
			my $result = $_;
			if ($_ eq "\$\$") {
				$result = shift @use_args;
			}
			if ($_ =~ "sub ?\{") {
				$result = eval($_);
				if ($@) {
					print STDERR "Syntax error $@ in $_\n";
				}
			}
			$result;
		} @arguments;
	
		if ($requires_stats) {
			unshift @arguments, $stats_ref;
		}
		if ($requires_list) {
			unshift @arguments, $dirs_ref;
		}

		return (\@arguments, \@use_args);
	} else {
		return ($dirs_to_list, $use_args_ref);
	}
}

# Based on "$$" argvalues splits given program args to the "$$"-ones and to the rest
sub extract_dirs_to_list($$) {
	my ($program_ref, $program_args_ref) = @_;

	my @program_args = @{ $program_args_ref };
	my @use_args = ();

	walk_program($program_ref, sub {
			my ($instruction_ref,$function_name,$function_method,$requires_list,$requires_stats,$params_ref,$args_ref) = @_;
		
			for my $arg (@{ $args_ref }) {
				if ($arg eq "\$\$") {
					my $value = shift @program_args;
					push @use_args, $value;
				}
			}
	});
	
	return (\@use_args, \@program_args);
}


#######################################

# Utility method for simplified walking throught an program.
sub walk_program($$) {
	my ($program_ref, $instruction_runner) = @_;

	for my $instruction (@{ $program_ref }) {
		my $function_ref = $instruction->{"function"};
		
		my $function_name = $function_ref->{"name"};
		my $function_method = $function_ref->{"method"};
		my $requires_list = $function_ref->{"requires_list"};
		my $requires_stats = $function_ref->{"requires_stats"};
		my $params_ref = $function_ref->{"params"};

		my $args_ref = $instruction->{"arguments"};
	
		$instruction_runner->
			($instruction, $function_name, $function_method, $requires_list, $requires_stats, $params_ref, $args_ref);
	}
}

# Lists all the supported Disketo_Extras's methods with all the required informations about them
sub functions_table() {
	my %table = (
		"list_all_directories" => { "name" => "list_all_directories", "method" => \&Disketo_Extras::list_all_directories,
			"requires_list" => 0, "requires_stats" => 0, "params" => []},
		"load_stats" => { "name" => "load_stats", "method" => \&Disketo_Extras::load_stats,
			"requires_list" => 1, "requires_stats" => 0, "params" => []},
		"filter_directories_custom" => { "name" => "filter_directories_custom", "method" => \&Disketo_Extras::filter_directories_custom,
			"requires_list" => 1, "requires_stats" => 0, "params" => ["predicate"]},
		"filter_directories_by_pattern" => { "name" => "filter_directories_by_pattern", "method" => \&Disketo_Extras::filter_directories_by_pattern,
			"requires_list" => 1, "requires_stats" => 0, "params" => ["pattern"]},
		"filter_directories_by_files_pattern" => { "name" => "filter_directories_by_files_pattern", "method" => \&Disketo_Extras::filter_directories_by_files_pattern,
			"requires_list" => 1, "requires_stats" => 0, "params" => ["pattern", "threshold"]},
		"filter_directories_matching" => { "name" => "filter_directories_matching", "method" => \&Disketo_Extras::filter_directories_matching,
			"requires_list" => 1, "requires_stats" => 0, "params" => ["matcher"]},
		"filter_directories_of_same_name" => { "name" => "filter_directories_of_same_name", "method" => \&Disketo_Extras::filter_directories_matching,
			"requires_list" => 1, "requires_stats" => 0, "params" => []},
		"filter_directories_with_common_files" => { "name" => "filter_directories_with_common_files", "method" => \&Disketo_Extras::filter_directories_with_common_files,
			"requires_list" => 1, "requires_stats" => 0, "params" => ["min_count", "files_matcher"]},
		"filter_directories_with_common_file_names" => { "name" => "filter_directories_with_common_file_names", "method" => \&Disketo_Extras::filter_directories_with_common_file_names,
			"requires_list" => 1, "requires_stats" => 0, "params" => ["min_coun"]},
		"filter_directories_with_common_file_names_with_size" => { "name" => "filter_directories_with_common_file_names_with_size", "method" => \&Disketo_Extras::filter_directories_with_common_file_names_with_size,
			"requires_list" => 1, "requires_stats" => 1, "params" => ["min_count"]},
		"print_directories_simply" => { "name" => "print_directories_simply", "method" => \&Disketo_Extras::print_directories_simply,
			"requires_list" => 1, "requires_stats" => 0, "params" => []},
		"print_directories" => { "name" => "print_directories", "method" => \&Disketo_Extras::print_directories,
			"requires_list" => 1, "requires_stats" => 0, "params" => ["printer"]},
		"print_files" => { "name" => "print_files", "method" => \&Disketo_Extras::print_files,
			"requires_list" => 1, "requires_stats" => 0, "params" => ["printer"]}
		#		"X" => { "name" => "X", "method" => \&Disketo_Extras::X
		#	"requires_list" => 1, "requires_stats" => 1, "params" => ["Y", "Z"]},
	);

	return \%table;
}
