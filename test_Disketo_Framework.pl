#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

use Data::Dumper;
use List::Util;
use Disketo_Utils;
use Disketo_Framework;

#######################################
#######################################

my $input_1 = "test/";
my $dirs_1_ref = Disketo_Framework::children_of($input_1);

Disketo_Utils::logit("children_of:");
print Dumper($dirs_1_ref);

#######################################

my $input_2 = "test/";
my $dirs_2_ref = Disketo_Framework::list_directory($input_2);

Disketo_Utils::logit("list_directory:");
print Dumper($dirs_2_ref);


#######################################

my @input_3 = ("test/ipsum", "test/lorem/", "test/dolor/");
my $dirs_3_ref = Disketo_Framework::list_all_directories(@input_3);

Disketo_Utils::logit("list_all_directories:");
print Dumper($dirs_3_ref);

#######################################

my ($dirs_3a_ref, $stats_3a_ref) = Disketo_Framework::load_stats($dirs_3_ref);

Disketo_Utils::logit("load_stats: dirs");
print Dumper($dirs_3a_ref);

Disketo_Utils::logit("load_stats: stats");
print Dumper($stats_3a_ref);


#######################################
#######################################
if (0) {
#######################################


my $filter_4 = sub { (length (shift @_)) % 2 };
my $dirs_4_ref = Disketo_Framework::filter_directories($dirs_3_ref, $filter_4);

Disketo_Utils::logit("filter_directories:");
print Dumper($dirs_4_ref);

#######################################

my $pattern_5 = "ba";
my $dirs_5_ref = Disketo_Framework::filter_directories_by_pattern($dirs_3_ref, $pattern_5);

Disketo_Utils::logit("filter_directories_by_pattern:");
print Dumper($dirs_5_ref);

#######################################

my $pattern_6 = "txt";
my $threshold_6 = 1;
my $dirs_6_ref = Disketo_Framework::filter_directories_by_files_pattern($dirs_3_ref, $pattern_6, $threshold_6);

Disketo_Utils::logit("filter_directories_by_files_pattern:");
print Dumper($dirs_6_ref);

#######################################
#######################################

my $matcher_7 = sub { my ($left, $lcr, $right, $rcr) = @_; 
	## Disketo_Utils::logit("$left <-> $right"); 
	return (scalar @{ $lcr } ) == (scalar @{ $rcr } ); 
};
my ($dirs_7_ref, $pairs_7_ref) = Disketo_Framework::filter_directories_matching($dirs_3_ref, $matcher_7);

Disketo_Utils::logit("filter_directories_matching: filtered");
print Dumper($dirs_7_ref);
Disketo_Utils::logit("filter_directories_matching: pairs");
print Dumper($pairs_7_ref);


#######################################

my ($dirs_8_ref, $pairs_8_ref) = Disketo_Framework::filter_directories_of_same_name($dirs_3_ref);

Disketo_Utils::logit("filter_directories_of_same_name: filtered");
print Dumper($dirs_8_ref);
Disketo_Utils::logit("filter_directories_of_same_name: pairs");
print Dumper($pairs_8_ref);

#######################################
}
#######################################

my $matcher_9 = sub { my ($left, $right) = @_; 
	Disketo_Utils::logit("$left <=> $right ");
	return (($left =~ /txt$/) and ($right =~ /txt$/)); 
};
my $min_count_9 = 1;

my ($dirs_9_ref, $pairs_9_ref) = Disketo_Framework::filter_directories_with_common_files($dirs_3_ref, $min_count_9, $matcher_9);

Disketo_Utils::logit("filter_directories_with_common_files: filtered");
print Dumper($dirs_9_ref);
Disketo_Utils::logit("filter_directories_with_common_files: pairs");
print Dumper($pairs_9_ref);

#######################################

my ($dirs_10_ref, $pairs_10_ref) = Disketo_Framework::filter_directories_with_common_file_names($dirs_3_ref, $min_count_9);

Disketo_Utils::logit("filter_directories_with_common_file_names: filtered");
print Dumper($dirs_10_ref);
Disketo_Utils::logit("filter_directories_with_common_file_names: pairs");
print Dumper($pairs_10_ref);

#######################################

my ($dirs_11_ref, $pairs_11_ref) = Disketo_Framework::filter_directories_with_common_file_names_with_size($dirs_3_ref, $stats_3a_ref, $min_count_9);

Disketo_Utils::logit("filter_directories_with_common_file_names_with_size: filtered");
print Dumper($dirs_11_ref);
Disketo_Utils::logit("filter_directories_with_common_file_names_with_size: pairs");
print Dumper($pairs_11_ref);

#######################################

my $printer_12 = sub () {
	my $dir = shift @_;
	my @children = @{ %{$dirs_3_ref}{$dir} };
	my $child_count = scalar @children;
	my $child_size = List::Util::sum (map { %{ $stats_3a_ref }{$_}->size } @children);

	return "$dir \t ($child_count children, total $child_size Bytes)";
};

Disketo_Utils::logit("print_directories");
Disketo_Framework::print_directories($dirs_3_ref, $printer_12);

#######################################

Disketo_Utils::logit("print_directories_simply");
Disketo_Framework::print_directories_simply($dirs_3_ref);



#TODO
