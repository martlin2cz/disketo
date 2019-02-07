#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

use Data::Dumper;
use Disketo_Utils;
use Disketo_Extras;

#######################################
Disketo_Utils::usage(\@ARGV, "<PATTERN FOR DIRECTORY NAMES> <DIRECTORIES...>");

my $pattern = shift @ARGV;
my @roots = @ARGV;

my $dirs_ref = Disketo_Extras::list_all_directories(@roots);

$dirs_ref = Disketo_Extras::filter_directories_by_pattern($dirs_ref, $pattern);

Disketo_Extras::print_directories_simply($dirs_ref);
