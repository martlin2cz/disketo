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


sub run($@) {
	my $script = shift @_;
	my @params = @_;

	my $program_ref = parse($script);
	evaluate($program_ref, \@params);
}

#######################################

sub parse($) {
	my ($script_file) = (@_);
	
	my $content = load_file($script_file);
	my $simply_parsed_ref = parse_simply($content);
	
	#TODO 

	return $simply_parsed_ref;
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

sub parse_simply($) {
	my ($content) = @_;

	my @pseudotokens = pseudotokenize($content);
	my @result = ();
	for my $pt (@pseudotokens) {
		#TODO
	}

}

sub pseudotokenize($) {
	my ($content) = @_;

	my @lines = split(/(\n)/, $content);
	my @result = ();
	for my $line (@lines) {
		my @parts = split(/(?<=(\t))/, $line);
		
		@result = (@result, @parts);
	}

	return @result;
}
