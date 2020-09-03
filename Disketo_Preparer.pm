#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

package Disketo_Preparer;
my $VERSION=3.0.0;

use Data::Dumper;
use Disketo_Utils;
use Disketo_Extras;
use Disketo_Instruction_Set;
use Disketo_Analyser;

########################################################################
# RESOLVE VALUES

# TODO



########################################################################
# FILL MISSING METAS

# Inserts instructions producing required metas
sub fill_requireds($$) {
	my ($program, $commands) = @_;
	
	my @new_program = ();
	my @produced = [];
	Disketo_Analyser::walk_program($program, sub {
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
