#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

use Data::Dumper;
use Disketo_Utils;
use Disketo_Extras;

#######################################
Disketo_Utils::usage(\@ARGV, "<DIRECTORIES...>");
my @roots = @ARGV;

my $dirs_ref = Disketo_Extras::list_all_directories(@roots);

Disketo_Extras::print_directories($dirs_ref, sub() {
		my $dir = shift @_;
		
    my @parts = split(/\/+/, $dir);
    my $name = pop @parts;
    my $count = scalar @parts;
    
		return ("|  " x $count) . "+ $name";		
	});
