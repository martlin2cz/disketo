#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

package Disketo_Interpreter;
my $VERSION=3.0.0;

use Data::Dumper;
use Disketo_Utils;
use Disketo_Engine;
use Disketo_Instruction_Set;

########################################################################
# Does the actual job with the disketo program. Prints usage, prints 
# the instructions, or runs the program itself.
# This includes the processing of the actual script arguments.
########################################################################

# Runs the given program. What else?
sub run_program($) {
	my ($program) = @_;
	
	compute_actual_methods($program);
	run_the_program_or_dry($program);
}

# Dry-runs the given program. Prints all as usual, but no work is done.
sub dry_run_program($) {
	my ($program) = @_;
	
	# TODO even during the dry-run compute the actual methods
	# for case it would fail for some (for instance due the internal error)
	# reason during that
	run_the_program_or_dry($program);
	
}

########################################################################

# Prints the program (with arguments)
# TODO move to Help module
sub print_program($) {
	my ($program) = @_;

	print("The script will run following statements:\n");
	
	Disketo_Analyser::walk_forrest($program, 
		sub { 
			my ($node, $stack, $param_name, $name, $operation, $params, $arguments) = @_; 
			
			my $padding = "    " x ((scalar @$stack) - 1);
			print("$padding where [$param_name] will invoke [$name]:\n");
			#TODO if empty params, no ":" at end
		},
		sub { 
			my ($node, $stack, $param_name, $name, $value, $prepared_value) = @_;
			
			my $padding = "    " x ((scalar @$stack) - 1);
			if (not defined($prepared_value)) {
				print("$padding where [$param_name] $name will be '$value'\n");
			} elsif ($value eq '$$') {
				print("$padding where [$param_name] $name will be '$value', which is actually '$prepared_value'\n");
			} elsif ($value eq '$$$') {
				my $joined = join(", ", @$prepared_value);
				print("$padding where [$param_name] $name will be '$value', which is actually '$joined'\n");
			} elsif ($value =~ /sub *\{(.+)\}/) {
				my $sub = $value; #TODO shorten and onelinify
				print("$padding where [$param_name] $name will be '$sub'\n");
			} else {
				print("$padding where [$param_name] $name will be '$value'\n");
			}
		});
}

########################################################################

# Computes the "actual methods" of the each instruction.
# Triggers the instruction's operation's "method" function and obtained
# annonymous subs stores as "actual method" field to each instruction 
# root node.
sub compute_actual_methods($) {
	my ($program) = @_;

	for my $instruction (@$program) {
		
		my $operation = $instruction->{"operation"};
		my $method = $operation->{"method"};
		my @method_args = ($instruction);
		
		my $actual_method = $method->(@method_args);
		$instruction->{"actual method"} = $actual_method;
	}
}

# Runs (or dry runs) the given program. 
# Dry runs if the instructions has no "actual method" field specified.
sub run_the_program_or_dry($) {
	my ($program) = @_;

	my $context = Disketo_Engine::create_context();
	
	for my $instruction (@$program) {
		my $human_name = human_name($instruction);
		
		my $count = scalar keys %{ $context->{"resources"} };
		if ($count == 0) {
			Disketo_Utils::logit("Executing ${human_name}...");
		} else {
			Disketo_Utils::logit("Executing ${human_name}on $count directories ...");
		}
				
		my $actual_method = $instruction->{"actual method"};
		if ($actual_method) {
			my @method_args = ($context);
			$actual_method->(@method_args);
		}
		
		Disketo_Utils::logit("Executed  ${human_name}!");
	}
}

# Generates the human readable, one-lined, name of the instruction. 
sub human_name($) {
	my ($instruction) = @_;
	
	my $result = "";
	
	Disketo_Analyser::walk_tree($instruction, "",
		sub { 
			my ($node, $stack, $param_name, $name, $operation, $params, $arguments) = @_;
			my $command_name = $operation->{"name"};
				$result .= "$command_name ";
		},
		sub { 
			my ($node, $stack, $param_name, $name, $value, $prepared_value) = @_; 
			
			if ($value =~ "sub ?\{") {
				$result .= "sub{...} ";
			} elsif ($value eq '$$') {
				$result .= "$prepared_value ";
			} elsif ($value eq '$$$') {
				$result .= join(", ", @$prepared_value)." ";
			} else {
				$result .= "$value ";
			}
		});
	
	return $result;
}

########################################################################
