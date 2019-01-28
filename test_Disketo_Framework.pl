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

my ($dirs_3a_ref, $stats_3a_ref) = Disketo_Framework::load_stats($dirs_3_ref);

print "load_stats: dirs\n";
print Dumper($dirs_3a_ref);

print "load_stats: stats\n";
print Dumper($stats_3a_ref);


#######################################

##my $filter_4 = sub { (length (shift @_)) % 2 };
##my %dirs_4 = Disketo_Framework::filter_directories(\%dirs_3, $filter_4);

##print "filter_directories:\n";
##print Dumper(\%dirs_4);

#######################################

##my $pattern_5 = "ba";
##my %dirs_5 = Disketo_Framework::filter_directories_by_pattern(\%dirs_3, $pattern_5);

##print "filter_directories_by_pattern:\n";
##print Dumper(\%dirs_5);

#######################################

##my $pattern_6 = "txt";
##my $threshold_6 = 1;
##my %dirs_6 = Disketo_Framework::filter_directories_by_files_pattern(\%dirs_3, $pattern_6, $threshold_6);

##print "filter_directories_by_files_pattern:\n";
##print Dumper(\%dirs_6);

#######################################

##my $matcher_7 = sub { my ($left, $lcr, $right, $rcr) = @_; print "$left <-> $right\n"; return 1; };
##my %dirs_7 = Disketo_Framework::filter_directories_matching(\%dirs_3, $matcher_7);

##print "filter_directories_matching:\n";
##print Dumper(\%dirs_7);

#######################################

#my %dirs_8 = Disketo_Framework::filter_directories_of_same_name(\%dirs_3);

#print "filter_directories_of_same_name:\n";
#print Dumper(\%dirs_8);



