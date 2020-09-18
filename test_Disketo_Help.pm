#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

use Data::Dumper;
use Disketo_Help;
use Disketo_Utils;

########################################################################
Disketo_Utils::logit("(commands)");
my $commands = Disketo_Instruction_Set::commands();
#print(Dumper($commands));

########################################################################
Disketo_Utils::logit("tree_usage");

print(Disketo_Help::tree_usage($commands));

########################################################################
Disketo_Utils::logit("print_tree_usage");

Disketo_Help::print_tree_usage();
########################################################################
Disketo_Utils::logit("linear_usage");

print(Dumper(Disketo_Help::linear_usage($commands)));

########################################################################
Disketo_Utils::logit("print_linear_usage");

Disketo_Help::print_linear_usage();

########################################################################
Disketo_Utils::logit("combine");
my $list_of_lists4a = [["foo", "bar", "baz"], [42, 99]];
my $combinations4a = Disketo_Help::combine($list_of_lists4a);
print(Dumper($list_of_lists4a, $combinations4a));

########################################################################

Disketo_Utils::logit("print_list_of_commands_in_markdown");

Disketo_Help::print_list_of_commands_in_markdown();
