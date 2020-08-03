#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

package Disketo_Analyser;
my $VERSION=2.2.0;

use Data::Dumper;
use Disketo_Utils;
use Disketo_Extras;
use Disketo_Instruction_Set;

########################################################################

# Implements the syntactic and semantic analysis of the disketo script.
# Results in the disketo program. 
# Does all the static analysis, without knowledge of the particular 
# script arguments which is the script beeing called with.

########################################################################

# Runs the semantic analysis. Takes a script ref, returns program ref.
sub analyse($) {
	my ($script) = @_;
	my $commands = Disketo_Instruction_Set::commands();
	
	my $program = compute_instructions($script, $commands);
	$program = fill_requireds($program, $commands);
	
	return $program;
}

########################################################################

# Computes the instructions for the given script
sub compute_instructions($$) {
	my ($script, $commands) = @_;
	my @instructions = ();

	for my $statement (@{ $script }) {
		my $instruction = compute_instruction($statement, $commands);
		push @instructions, $instruction;
	}

	return \@instructions;
}

# Computes the instruction for the given statement.
sub compute_instruction($$) {
	my ($statement, $commands) = @_;
	my ($command_name, $arguments) = extract($statement);

	my $command = validate_command_name($command_name, $commands);
	my $params = validate_command_params($arguments, $command);

	my %instruction = ( "command" => $command, "arguments" => $arguments );
	return \%instruction;
}

########################################################################


# Extracts the command name and arguments from the given statement
sub extract($) {
	my ($statement) = @_;
	
	my @statement = @{ $statement };
	my $command_name = shift @statement;
	
	return ($command_name, \@statement);
}


# Validates given command name (checks its existence agains given commands table)
sub validate_command_name($$) {
	my ($command_name, $commands) = @_;
	
	my $command = %{ $commands }{$command_name};
	if (!$command) {
		die("Unknown command \"$command_name\"");
	}

	return $command;
}

# Validates given command params (checks the number of them)
sub validate_command_params($$) {
	my ($arguments, $command) = @_;
	my @params = @{ $command->{"params"} };
	my @arguments = @{ $arguments };

	if ((scalar @params) ne (scalar @arguments)) {
		my $command_name = $command->{"name"};
		die("$command_name expects " . (scalar @params) . " params (" . join(", ", @params) . "), "
				. "given " . (scalar @arguments) . " (". join(", ", @arguments) . ")");
	}

	return \@params;
}

########################################################################

# Inserts instructions producing required metas
sub fill_requireds($$) {
	my ($program, $commands) = @_;
	
	my @new_program = ();
	my @produced = [];
	walk_program($program, sub {
		my ($instruction,$command_name,$command,$args,$resolved_args) = @_;
		
		my $missings = find_missing_required_metas($command, \@produced);
		for my $missing_meta_name (@{ $missings }) {
			my $new_command = find_first_command_producing_meta($missing_meta_name, $commands);
			if (!$new_command) {
				die("Meta '" . $missing_meta_name . "' is not produced by any command\n");
			}
			
			my $new_instruction = Disketo_Instruction_Set::prepending_instruction($instruction, $new_command);
			push @new_program, $new_instruction;
		}
		
		if ($command->{"produces"}) {
			push @produced, $command->{"produces"};
		}
		
		push @new_program, $instruction;
	});
	
	return \@new_program;
}

# Computes the array of metas names which are required by the given command but not yet produced
sub find_missing_required_metas($$) {
	my ($command, $produced) = @_;
	
	my @requireds = @{ $command->{"requires"} };
	my @produceds = @{ $produced };
	my @missings = ();

	for my $required (@requireds) {
		my $found = 0;
		
		for my $produced (@produceds) {
			if ($required eq $produced) {
				$found = 1;
			}
		}
		
		if ($found eq 0) {
			push @missings, $required;
		}
	}
	
	return \@missings;
}

# Returns first command producing the given meta.
sub find_first_command_producing_meta($$) {
	my ($required_meta, $commands) = @_;
       
	my %commands = %{ $commands };
               
	for my $another_command (values %commands) {
		if ($another_command->{"produces"} eq $required_meta) {
			return $another_command;
		}
	}
	
	return undef;
}


########################################################################

# Utility method for simplified walking throught an program.
sub walk_program($$) {
	my ($program, $instruction_runner) = @_;

	for my $instruction (@{ $program }) {
		my $command = $instruction->{"command"};
		my $args = $instruction->{"arguments"};
		my $resolved_args = $instruction->{"resolved_args"};
		
		my $command_name = $command->{"name"};
	
		$instruction_runner->
			($instruction, $command_name, $command, $args, $resolved_args);
	}
}
