#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

use Data::Dumper;
use Disketo_Framework;

#######################################
#######################################

my $input_1 = "test/";
my $dirs_1_ref = Disketo_Framework::children_of($input_1);

print "children_of:\n";
print Dumper($dirs_1_ref);

#######################################

my $input_2 = "test/";
my $dirs_2_ref = Disketo_Framework::list_directory($input_2);

print "list_directory:\n";
print Dumper($dirs_2_ref);


#######################################

my @input_3 = ("test/ipsum", "test/lorem/");
my $dirs_3_ref = Disketo_Framework::list_all_directories(@input_3);

print "list_all_directories:\n";
print Dumper($dirs_3_ref);

#######################################
if (0) {
#######################################

my ($dirs_3a_ref, $stats_3a_ref) = Disketo_Framework::load_stats($dirs_3_ref);

print "load_stats: dirs\n";
print Dumper($dirs_3a_ref);

print "load_stats: stats\n";
print Dumper($stats_3a_ref);


#######################################
#######################################

my $filter_4 = sub { (length (shift @_)) % 2 };
my $dirs_4_ref = Disketo_Framework::filter_directories($dirs_3_ref, $filter_4);

print "filter_directories:\n";
print Dumper($dirs_4_ref);

#######################################

my $pattern_5 = "ba";
my $dirs_5_ref = Disketo_Framework::filter_directories_by_pattern($dirs_3_ref, $pattern_5);

print "filter_directories_by_pattern:\n";
print Dumper($dirs_5_ref);

#######################################

my $pattern_6 = "txt";
my $threshold_6 = 1;
my $dirs_6_ref = Disketo_Framework::filter_directories_by_files_pattern($dirs_3_ref, $pattern_6, $threshold_6);

print "filter_directories_by_files_pattern:\n";
print Dumper($dirs_6_ref);

#######################################
#######################################

my $matcher_7 = sub { my ($left, $lcr, $right, $rcr) = @_; 
	## print "$left <-> $right\n"; 
	return (scalar @{ $lcr } ) == (scalar @{ $rcr } ); 
};
my ($dirs_7_ref, $pairs_7_ref) = Disketo_Framework::filter_directories_matching($dirs_3_ref, $matcher_7);

print "filter_directories_matching: filtered\n";
print Dumper($dirs_7_ref);
print "filter_directories_matching: pairs\n";
print Dumper($pairs_7_ref);


#######################################

my ($dirs_8_ref, $pairs_8_ref) = Disketo_Framework::filter_directories_of_same_name($dirs_3_ref);

print "filter_directories_of_same_name: filtered\n";
print Dumper($dirs_8_ref);
print "filter_directories_of_same_name: pairs\n";
print Dumper($pairs_8_ref);

#######################################
}
#######################################

my $matcher_9 = sub { my ($left, $right) = @_; 
	print "$left <=> $right \n";
	return (($left =~ /txt$/) and ($right =~ /txt$/)); 
};
my $min_count_9 = 2;

my ($dirs_9_ref, $pairs_9_ref) = Disketo_Framework::filter_directories_with_common_files($dirs_3_ref, $min_count_9, $matcher_9);

print "filter_directories_with_common_files: filtered\n";
print Dumper($dirs_9_ref);
print "filter_directories_with_common_files: pairs\n";
print Dumper($pairs_9_ref);


#TODO
