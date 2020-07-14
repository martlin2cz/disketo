#!/usr/bin/perl
use strict;

package Disketo_Instruction_Set; 
my $VERSION=2.0.0;
  
use Disketo_Instructions; 

  
########################################################################
# The instruction set. Creates the mapping between the disketo script
# statements and particular perl functions.
########################################################################

sub commands() {
	my %table = (
		# GENERATE INSTRUCTIONS HERE
	);
	
	return \%table;
}

sub prepending_instruction($$) {
	my ($instruction, $prepending_command) = @_;
	
	my $command = $prepending_command->{"statement_name"};
	my $arguments = [];
	
	#TODO arguments := if $prepending_instruction takes XYZ, then pick from $instruction 
	
	return {"command" => $command, "arguments" => $arguments };
}
