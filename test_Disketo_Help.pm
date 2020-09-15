#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

use Data::Dumper;
use Disketo_Help;

########################################################################
Disketo_Utils::logit("(commands)");
my $commands = Disketo_Instruction_Set::commands();
#print(Dumper($commands));

########################################################################
print("tree_usage\n");

#print(Disketo_Help::tree_usage());

########################################################################
print("linear_usage\n");

print(Dumper(Disketo_Help::linear_usage()));

########################################################################
print("combine\n");
my $list_of_lists4a = [["foo", "bar", "baz"], [42, 99]];
my $combinations4a = Disketo_Help::combine($list_of_lists4a);
print(Dumper($list_of_lists4a, $combinations4a));

########################################################################
print("TODO\n");
