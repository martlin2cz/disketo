#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

use Data::Dumper;
use Disketo_Utils;
use Disketo_Extras;

#######################################
Disketo_Utils::usage(\@ARGV, "<PATTERN FOR FILE NAMES> <MINIMAL COUNT OF SUCH FILES> <DIRECTORIES...>");

my $pattern = shift @ARGV;
my $min_count = shift @ARGV;
my @roots = @ARGV;

my $dirs_ref = Disketo_Extras::list_all_directories(@roots);

$dirs_ref = Disketo_Extras::filter_directories_by_files_pattern($dirs_ref, $pattern, $min_count);

Disketo_Extras::print_directories_simply($dirs_ref);
