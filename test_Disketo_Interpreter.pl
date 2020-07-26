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
Disketo_Utils::logit("parse");
my $script7a = "test/scripts/simple.ds";
my ($program7a_ref) = Disketo_Parser::parse($script7a);
print Dumper($program7a_ref);


#######################################
my @program_args_6a = ("foo", "bar", "baz");

#######################################
Disketo_Utils::logit("print_usage");
my @arguments8a = ("foo");
### Disketo_Evaluator::print_usage($script7a, $program7a_ref, \@arguments8a);

#######################################
Disketo_Utils::logit("print_program");
Disketo_Interpreter::print_program($program7a_ref, \@program_args_6a);

#######################################
Disketo_Utils::logit("prepare");
my ($prepared10_ref) = Disketo_Evaluator::prepare($program7a_ref, \@program_args_6a);
print Dumper($prepared10_ref);



