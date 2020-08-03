#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

use Data::Dumper;
use List::Util;
use Disketo_Utils;

use Disketo_Engine;

use Disketo_Instructions;


#######################################

my $context = Disketo_Engine::create_context();
my $roots = ["test/dolor", "test/ipsum", "test/lsof.txt"];

Disketo_Instructions::load($context, $roots);
########################################################################
my $file_matcher = sub($$) { return (shift @_); };
my $files_matcher = sub($$) { return (shift @_); };
my $files_pattern = "(.*)";

my $matcher = sub($$) { return (shift @_); };
my $groupper = sub($$) { return substr((shift @_), 0, 3); };
my $printer = sub($$) { return (shift @_); };
my $computer = sub($$) { return (shift @_); };

my $pattern = "(.*)";
my $count = 1;

my $some_files_name = "something for files";
my $some_dirs_name = "something for dirs";
my $files_group_name = "some files group";
my $dirs_group_name = "some dirs group";
########################################################################

Disketo_Instructions::group_files_by_names($context);
Disketo_Instructions::group_dirs_by_names($context);
Disketo_Instructions::compute_files_matching($matcher, $context);
Disketo_Instructions::compute_dirs_matching($matcher, $context);
Disketo_Instructions::compute_files_of_dir_matching($file_matcher, $context);

########################################################################

Disketo_Instructions::group_files_by_name($context);
Disketo_Instructions::group_dirs_by_name($context);
Disketo_Instructions::group_files_by_custom($context, $groupper, $files_group_name);
Disketo_Instructions::group_dirs_by_custom($context, $groupper, $dirs_group_name);

########################################################################

Disketo_Instructions::count_files($context);
Disketo_Instructions::compute_custom_for_each_dir($context, $some_dirs_name, $computer);
Disketo_Instructions::compute_custom_for_each_file($context, $some_files_name, $computer);
Disketo_Instructions::load_stats($context);

########################################################################

Disketo_Instructions::filter_dirs_matching_pattern($context, $pattern);
Disketo_Instructions::filter_dirs_matching_custom($context, $matcher);
Disketo_Instructions::filter_dirs_with_files_matching_pattern($context, $files_pattern, $count);
Disketo_Instructions::filter_dirs_with_files_matching_custom($context, $files_matcher, $count);
Disketo_Instructions::filter_files_matching_pattern($context, $pattern);
Disketo_Instructions::filter_files_matching_custom($context, $matcher);

########################################################################

Disketo_Instructions::filter_custom_duplicate_files($context, $files_group_name, $groupper);
Disketo_Instructions::filter_duplicate_files_by_name($context);
Disketo_Instructions::filter_custom_duplicate_dirs($context, $dirs_group_name, $groupper);
Disketo_Instructions::filter_duplicate_dirs_by_name($context);

########################################################################

Disketo_Instructions::filter_dirs_by_duplicate_files_by_name($context, $count);
Disketo_Instructions::filter_dirs_by_custom_duplicate_files($context, $groupper, $count);

########################################################################

Disketo_Instructions::print_dirs_simply($context);
Disketo_Instructions::print_dirs_custom($context, $printer);
Disketo_Instructions::print_files_simply($context);
Disketo_Instructions::print_files_custom($context, $printer);

########################################################################

Disketo_Engine::context_stats($context);
