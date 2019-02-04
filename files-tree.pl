#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

use Data::Dumper;
use Disketo_Utils;
use Disketo_Extras;

#######################################

my @roots = @ARGV;

my $dirs_ref = Disketo_Extras::list_all_directories(@roots);

Disketo_Extras::print_files($dirs_ref, sub() {
		my $file = shift @_;
		
    my @parts = split(/\/+/, $file);
    my $name = pop @parts;
    my $count = scalar @parts;
    
		return ("|  " x $count) . "+ $name";		
	});
