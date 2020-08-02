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
		# GENERATE INSTRUCTIONS HERE
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
	if ($prepending_command->{"name"} eq "load") {
		$prepending_arguments = [];

	} elsif ($params ~~ $prepending_params) {
		$prepending_arguments = $arguments;

	#TODO arguments := if $prepending_instruction takes XYZ, then pick from $instruction

	} else {
		print(Dumper($prepending_command, $command));
		die("Unimplemented prepend of " . $prepending_command->{"name"} . " before " . $command->{"name"});
	}
	
	return {"command" => $prepending_command, "arguments" => $prepending_arguments };
}
