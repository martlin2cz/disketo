#!/usr/bin/perl
use strict;

package Disketo_Instruction_Set; 
my $VERSION=2.0.0;
  
use Disketo_Instructions; 

  
########################################################################
# The instruction set. Creates the mapping between the disketo script
# statements and particular perl functions.
########################################################################

sub instructions() {
	my %table = (
		# GENERATE INSTRUCTIONS HERE
	);
	
	return \%table;
}
