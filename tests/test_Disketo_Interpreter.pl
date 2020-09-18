#!/usr/bin/perl

use strict;

use FindBin qw($Bin); 
use lib "$Bin/../module"; 

use Data::Dumper;
use Disketo_Utils;
use Disketo_Parser;
use Disketo_Analyser;
use Disketo_Preparer;
use Disketo_Instruction_Set;
use Disketo_Interpreter;

#######################################
#######################################
Disketo_Utils::logit("(commands)");
my $commands = Disketo_Instruction_Set::commands();

#######################################
Disketo_Utils::logit("(prepare program)");

my $file0a = "$Bin/testing-scripts/simple.ds";
my $script0a = Disketo_Parser::parse($file0a);
my $program0a = Disketo_Analyser::analyse($script0a);
my @arguments0a = ("foo", "$Bin/testing-resources");
Disketo_Preparer::prepare_to_execute($program0a, \@arguments0a);

print(Dumper($program0a));
#######################################
Disketo_Utils::logit("print_usage");

#TODO FIXME
my @arguments1a = ("foo", "bar");
#my $usage1a = Disketo_Interpreter::create_usage($file0a, $program0a, \@arguments1a);
#print($usage1a);

my $arguments1b = undef;
#my $usage1b = Disketo_Interpreter::create_usage($file0a, $program0a, $arguments1b);
#print($usage1b);

#######################################
Disketo_Utils::logit("print_program");

Disketo_Interpreter::print_program($program0a);

#######################################
Disketo_Utils::logit("run_program");

Disketo_Interpreter::run_program($program0a);

print("----\n");
Disketo_Interpreter::run_program($program0a);

# print("skipped because would die\n");


