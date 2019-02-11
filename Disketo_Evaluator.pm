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

	my @tokens = tokenize($content);
	my @result = ([]);
	for my $token (@tokens) {
		if ($token =~ /^\n$/) {
			push @result, [];
		} else {
			push @{ @result[-1] }, $token;
		}
	}

	return \@result;
}

sub tokenize($) {
	my ($content) = @_;

	my @parts = $content =~ / 
		(?# wrapped in curly backets, to use subs)
		(\{ (?: [^{}]* | (?0) )* \} ) | 
		(?# wrapped in double-quotes)
		(\" [^\"]* \") | 
		(?# regular text)
		( [\w]+ ) | 
		(?# pass newlines too)
		( \n ) /gx;
		
	#TODO if  "sub", "{...}" then replace with "sub {...}"
	my @filtered = grep /(.+)|(\n)/, @parts;

	return @filtered;
}

#######################################

sub validate() {
	#TODO for each line:
	#TODO  check whether the function exists
	#TODO  check whether requires loaded roots/stats
	#TODO  check argc in both terms (@ARGV and caller/callee match)
	#TODO  evaluate args?
	#TODO  extract @ARGV values, put into instead of $$s
}

sub print() {
	#TODO for each line:
	#TODO  print it somehow
}

sub evalueate() {
	#TODO for each line:
	#TODO  evaluate it somehow
}

