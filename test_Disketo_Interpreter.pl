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
my $usage1a = Disketo_Interpreter::create_usage($file0a, $program0a, \@arguments1a);
print($usage1a);

my $arguments1b = undef;
my $usage1b = Disketo_Interpreter::create_usage($file0a, $program0a, $arguments1b);
print($usage1b);

#######################################
Disketo_Utils::logit("collect_wildcarded_args");

my $collected2a = Disketo_Interpreter::collect_wildcarded_args($program0a);
print(Dumper($collected2a));


#######################################
Disketo_Utils::logit("print_program");

Disketo_Interpreter::print_program($program0a, \@arguments1a);


#######################################
Disketo_Utils::logit("insert_loads");

my @arguments3a = ("foo", "lorem", "ipsum", "dolor");
my $program3a = Disketo_Interpreter::insert_loads($program0a, \@arguments3a);
print Dumper($program3a);

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


