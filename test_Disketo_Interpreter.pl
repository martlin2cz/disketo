#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

use Data::Dumper;
use Disketo_Utils;
use Disketo_Parser;
use Disketo_Analyser;
use Disketo_Instruction_Set;
use Disketo_Interpreter;

#######################################
#######################################
Disketo_Utils::logit("(commands)");
my $commands = Disketo_Instruction_Set::commands();

#######################################
Disketo_Utils::logit("(prepare program)");

my $file0a = "test/scripts/simple.ds";
my $script0a = Disketo_Parser::parse($file0a);
my $program0a = Disketo_Analyser::analyse($script0a);

print(Dumper($program0a));
#######################################
Disketo_Utils::logit("print_usage");

my @arguments1a = ("foo");
### Disketo_Interpreter::print_usage($file0a, $program0a, \@arguments1a);
print("skipped because would die\n");

#######################################
Disketo_Utils::logit("print_program");

Disketo_Interpreter::print_program($program0a, \@arguments1a);

#######################################
Disketo_Utils::logit("resolve_args");

Disketo_Interpreter::resolve_args($program0a, \@arguments1a);
print Dumper($program0a);


#######################################
Disketo_Utils::logit("run_program");

Disketo_Interpreter::run_program($program0a, \@arguments1a);

print("----\n");
my @arguments4b = ("test/");
Disketo_Interpreter::run_program($program0a, \@arguments4b);

# print("skipped because would die\n");


