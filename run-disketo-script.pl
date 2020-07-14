#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

my $VERSION = 2.0.0;

use Disketo_Utils;
use Disketo_Evaluator;
use Disketo_Instruction_Set;

#######################################
my $dry_run = 0;

# check help
if ((scalar @ARGV > 0) and ((@ARGV[0] eq "-h") or (@ARGV[0] eq "--help"))) {
	print(STDERR "Disketo script executer\n");
	Disketo_Utils::usage([], "[--dry|--dry-run] <SCRIPT> <SCRIPT PARAMS...>\n" 
		. "Use --list or --list-functions to list supported functions\n"
		. "Use --help or -h to print this help\n"
		. "Use --version or -v to print the version\n");
}

# check version
if ((scalar @ARGV > 0) and ((@ARGV[0] eq "-v") or (@ARGV[0] eq "--version"))) {
	die("Disketo $VERSION \n");
}

# check list of functions
if ((scalar @ARGV > 0) and ((@ARGV[0] eq "--list") or (@ARGV[0] eq "--list-functions"))) {
  list_functions();
  die("That's all folks!");
}

# check dry run
if ((scalar @ARGV > 0) and ((@ARGV[0] eq "--dry") or (@ARGV[0] eq "--dry-run"))) {
  $dry_run = 1;
  shift @ARGV;
}

# check no args
Disketo_Utils::usage(\@ARGV, "[--dry|--dry-run] <SCRIPT> <SCRIPT PARAMS...>\n" 
	. "Run with --help for more info.\n");

# and run the script
my $script = shift @ARGV;
my @args = @ARGV;

Disketo_Evaluator::run($dry_run, $script, \@args);

#######################################

sub list_functions() {
	my $table_ref = Disketo_Instruction_Set::instructions();
	my %table = %{ $table_ref };

	for my $fnname (sort keys %table) {
		my $function_ref = $table{$fnname};
		my $doc = $function_ref->{"doc"};
		my $params_ref = $function_ref->{"params"};
	
		print STDERR "$fnname\t" . join ("  ", @{ $params_ref }) . "\n";
		print STDERR "\t$doc\n\n";

	}
}

