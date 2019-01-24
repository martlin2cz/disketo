#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

use Data::Dumper;
use Disketo_Framework;

#######################################
#######################################

my $input_1 = "test/";
my @dirs_1 = Disketo_Framework::children_of($input_1);

print "children_of:\n";
print Dumper(\@dirs_1);

#######################################

my $input_2 = "test/";
my %dirs_2 = Disketo_Framework::list_directory($input_2);

print "list_directory:\n";
print Dumper(\%dirs_2);


#######################################


my @input_10 = ("test/ipsum", "test/lorem/");
my %dirs_10 = Disketo_Framework::list_all_directories(@input_10);

print "list_all_directories:\n";
print Dumper(\%dirs_10);

#######################################


