#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

use Data::Dumper;
use Disketo_Utils;
use Disketo_Parser;
use Disketo_Analyser;
use Disketo_Instruction_Set;

my $script7a = "test/scripts/simple.ds";
my ($program7a_ref) = Disketo_Parser::parse($script7a);

#######################################
Disketo_Utils::logit("(instructions)");
my $table4_ref = Disketo_Instruction_Set::commands();


#######################################
Disketo_Utils::logit("validate_function");
my @statement5a = ("filter_dirs_matching_pattern", "42", "karel");
my ($statement5a_mod_ref, $fnname5a, $function5a_ref) = Disketo_Analyser::validate_function(\@statement5a, $table4_ref);
print Dumper($statement5a_mod_ref, $fnname5a, $function5a_ref);

my @statement5b = ("foo_bar_baz", "lorem", "ipsum");
### Disketo_Evaluator::validate_function(\@statement5b, $table4_ref);

#######################################
Disketo_Utils::logit("validate_params");
my @statement6a_mod = ("42", "karel", "\$\$", "\"boo\"", "sub { 99; }");
my @program_args_6a = ("foo", "bar", "baz");
my %function6 = ( "method" => &Disketo_Utils::logit, "params" => ["first", "second", "third", "fourth", "fifth"] );

my ($resolved_args6) = Disketo_Analyser::validate_params(\@statement6a_mod, $fnname5a, \%function6);
print Dumper($resolved_args6);

my @statement6b_mod = ("foo", "bar", "baz", "42");
### Disketo_Evaluator::validate_params(\@statement6b_mod, $fnname5a, \%function6);

my @statement6b_mod = ("\$\$", "\$\$", "\$\$", "\$\$", "\$\$");
### Disketo_Evaluator::validate_params(\@statement6b_mod, $fnname5a, \%function6);


#######################################
Disketo_Utils::logit("print_program");
Disketo_Analyser::print_program($program7a_ref, \@program_args_6a);




