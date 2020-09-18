#!/usr/bin/perl

use strict;
my $VERSION=3.00.0;

use FindBin qw($Bin); 
use lib "$Bin/../module"; 

use Disketo_Utils;
use Disketo_Scripter;

########################################################################

Disketo_Utils::check_args(\@ARGV,
	"dry-run.pl",
	"Disketo script dry-runner",
	"Dry-runs the given disketo script.",
	"<SCRIPT.ds> [SCRIPT ARGUMENT 1] ... [SCRIPT ARGUMENT n] [ROOT DIR OR FILE 1] ... [ROOT DIR OR FILE m]",
	undef, 1);
	
my $script = shift @ARGV;

Disketo_Scripter::dry_run_script($script, \@ARGV);

########################################################################



