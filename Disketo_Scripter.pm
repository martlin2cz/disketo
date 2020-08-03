#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

package Disketo_Scripter;
my $VERSION=2.1.1;

use Data::Dumper;
use Disketo_Utils;
use Disketo_Parser;
use Disketo_Analyser;
use Disketo_Instruction_Set;
use Disketo_Interpreter;

########################################################################
# Runs the script.
sub run_script($$) {
	my ($script_file, $program_arguments) = @_;
	
	my $script = Disketo_Parser::parse($script_file);
	my $program = Disketo_Analyser::analyse($script);
	my $program = Disketo_Interpreter::prepare($program, $program_arguments);
	
	Disketo_Interpreter::run_program($program, $program_arguments);
}


# Prints the script.
sub print_script($$) {
	my ($script_file, $program_arguments) = @_;
	
	my $script = Disketo_Parser::parse($script_file);
	my $program = Disketo_Analyser::analyse($script);
	
	Disketo_Interpreter::print_program($program, $program_arguments);
}

# Prints the script usage
sub print_usage($$) {
	my ($script_file, $program_arguments) = @_;
	
	my $script = Disketo_Parser::parse($script_file);
	my $program = Disketo_Analyser::analyse($script);
	
	my $usage = Disketo_Interpreter::compute_usage($program, $program_arguments);
	Disketo_Utils::print_usage([], $usage);
}
