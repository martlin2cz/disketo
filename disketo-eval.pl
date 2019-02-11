#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

use Disketo_Utils;
use Disketo_Evaluator;

#######################################
Disketo_Utils::usage(\@ARGV, "<SCRIPT> <SCRIPT PARAMS...>");

my $script = shift @ARGV;
my @params = @ARGV;

Disketo_Evaluator::run($script, @params);


