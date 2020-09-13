#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

my $VERSION=3.00.0;

use Disketo_Utils;
use Disketo_Scripter;

########################################################################

Disketo_Utils::check_args(\@ARGV,
	"parse.pl",
	"Disketo script parser and analyzer",
	"Parses, analyzes, verfies and finally prints structured the disketo script as it will be executed.",
	"<SCRIPT.ds> [SCRIPT ARGUMENT 1] ... [SCRIPT ARGUMENT n] [ROOT DIR OR FILE 1] ... [ROOT DIR OR FILE m]",
	undef, 1);
	
my $script = shift @ARGV;

Disketo_Scripter::print_program($script, \@ARGV);

########################################################################



