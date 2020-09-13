#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

package Disketo_Scripter;
my $VERSION=3.00.0;

use Data::Dumper;
use Disketo_Utils;
use Disketo_Parser;
use Disketo_Analyser;
use Disketo_Preparer;
use Disketo_Instruction_Set;
use Disketo_Interpreter;

########################################################################

# Just the fascade wrapping all the parser, analyser and interpreter 
# stuff.

########################################################################
# Runs the script.
sub run_script($$) {
	my ($script_file, $program_arguments) = @_;
	
	my $script = Disketo_Parser::parse($script_file);
	my $program = Disketo_Analyser::analyse($script);
	
	Disketo_Preparer::prepare_to_execute($program, $program_arguments);
	Disketo_Interpreter::run_program($program);
	
	return $program;
}

# Dry-runs the script.
sub dry_run_script($$) {
	my ($script_file, $program_arguments) = @_;
	
	my $script = Disketo_Parser::parse($script_file);
	my $program = Disketo_Analyser::analyse($script);
	
	Disketo_Preparer::prepare_to_execute($program, $program_arguments);
	Disketo_Interpreter::dry_run_program($program);
	
	return $program;
}


# Prints the parsed script.
sub print_program($$) {
	my ($script_file, $program_arguments) = @_;
	
	my $script = Disketo_Parser::parse($script_file);
	my $program = Disketo_Analyser::analyse($script);
	
	Disketo_Preparer::prepare_to_execute($program, $program_arguments);
	Disketo_Interpreter::print_program($program);
	
	return $program;
}

# Prints the script usage
sub print_usage($$) {
	my ($script_file, $program_arguments) = @_;
	
	my $script = Disketo_Parser::parse($script_file);
	my $program = Disketo_Analyser::analyse($script);
	
	my $usage = Disketo_Interpreter::compute_usage($program, $program_arguments);
	Disketo_Utils::print_usage([], $usage);
}

# Parses the statement
sub parse_statement($) {
	my ($statement) = @_;
	
	my $script = Disketo_Parser::parse_content($statement);
	my $program = Disketo_Analyser::analyse($script);
	
	return $program;
}

# Prints the tree of the allowed commands.
sub print_commands_tree() {
	my $usage = Disketo_Analyser::tree_usage();
	print($usage);
}
