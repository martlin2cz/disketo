#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

use Disketo_Utils;
use Disketo_Evaluator;

#######################################
my $dry_run = 0;

if ((scalar @ARGV > 0) and ((@ARGV[0] eq "--list") or (@ARGV[0] eq "--list-functions"))) {
  list_functions();
  die("That's all folks!");
}


if ((scalar @ARGV > 0) and ((@ARGV[0] eq "--dry") or (@ARGV[0] eq "--dry-run"))) {
  $dry_run = 1;
  shift @ARGV;
}

Disketo_Utils::usage(\@ARGV, "[--dry|--dry-run] <SCRIPT> <SCRIPT PARAMS...>\n" 
	. "Use --list or --list-functions to list supported functions");

my $script = shift @ARGV;
my @args = @ARGV;

Disketo_Evaluator::run($dry_run, $script, \@args);

#######################################

sub list_functions() {
	my $table_ref = Disketo_Evaluator::functions_table();
	my %table = %{ $table_ref };

	for my $fnname (sort keys %table) {
		my $function_ref = $table{$fnname};
		my $doc = $function_ref->{"doc"};
		my $params_ref = $function_ref->{"params"};
	
		print STDERR "$fnname\t" . join ("  ", @{ $params_ref }) . "\n";
		print STDERR "\t$doc\n\n";

	}
}

