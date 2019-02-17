#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

use Disketo_Utils;
use Disketo_Evaluator;

#######################################
my $dry_run = 0;
if ((scalar @ARGV > 0) and ((@ARGV[0] eq "--dry") or (@ARGV[0] eq "--dry-run"))) {
  $dry_run = 1;
  shift @ARGV;
}

Disketo_Utils::usage(\@ARGV, "[--dry|--dry-run] <SCRIPT> <SCRIPT PARAMS...>");

my $script = shift @ARGV;
my @args = @ARGV;

Disketo_Evaluator::run($dry_run, $script, \@args);


