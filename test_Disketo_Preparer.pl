#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

use Data::Dumper;
use Disketo_Utils;
use Disketo_Parser;
use Disketo_Analyser;
use Disketo_Instruction_Set;
use Disketo_Preparer;

#######################################
Disketo_Utils::logit("(parsing the file)");
my $file1a = "test/scripts/simple.ds";
my $script1a = Disketo_Parser::parse($file1a);
my $program1a = Disketo_Analyser::analyse($script1a);
Disketo_Analyser::print_syntax_forrest($program1a);

#######################################
Disketo_Utils::logit("(commands)");
my $commands = Disketo_Instruction_Set::commands();

#######################################
Disketo_Utils::logit("prepare_values");

Disketo_Preparer::prepare_values($program1a);
print(Dumper($program1a));

#######################################
Disketo_Utils::logit("resolve_values");

my $arguments4a = ["foo", "bar", "baz", "aux"];
my $remaining4a = Disketo_Preparer::resolve_values($program1a, $arguments4a);
print(Dumper($program1a));
print(Dumper($remaining4a));

my $arguments4b = [];
#my $remaining4b = Disketo_Preparer::resolve_values($program1a, $arguments4b);
print("Skipped, may fail.\n");

#######################################
Disketo_Utils::logit("(parsing the second file)");

my $file5a = "test/scripts/with-requires.ds";
my $script5a = Disketo_Parser::parse($file5a);
my $program5a = Disketo_Analyser::analyse($script5a);
Disketo_Analyser::print_syntax_forrest($program5a);

#######################################
Disketo_Utils::logit("compute_produceds");
my $instruction6compute = $program5a->[0];
my $instruction6print = $program5a->[1];

my $produceds6a = Disketo_Preparer::compute_produceds($instruction6compute);
print(Dumper($produceds6a));
my $produceds6b = Disketo_Preparer::compute_produceds($instruction6print);
print(Dumper($produceds6b));

#######################################
Disketo_Utils::logit("compute_requireds");
my $requireds7a = Disketo_Preparer::compute_requireds($instruction6compute);
print(Dumper($requireds7a));
my $requireds7b = Disketo_Preparer::compute_requireds($instruction6print);
print(Dumper($requireds7b));

#######################################
Disketo_Utils::logit("produces");
my $is8a = Disketo_Preparer::produces($instruction6compute, "whatever");
print(Dumper($is8a));
my $is8b = Disketo_Preparer::produces($instruction6compute, "files stats");
print(Dumper($is8b));

#######################################
Disketo_Utils::logit("verify_produceds");
Disketo_Preparer::verify_dependencies($program1a);

print("Skipped, may fail");
#Disketo_Preparer::verify_dependencies($program5a);

#~ #######################################
#~ Disketo_Utils::logit("find_missing_required_metas");

#~ my $command8a = {"requires" => ["foo meta", "bar meta", "lorem meta"]};

#~ #######################################
#~ Disketo_Utils::logit("find_missing_required_metas");

#~ my $command8a = {"requires" => ["foo meta", "bar meta", "lorem meta"]};
#~ my $produced8a = ["lorem meta", "ipsum meta"];
#~ my $missing8a = Disketo_Preparer::find_missing_required_metas($command8a, $produced8a);
#~ print(Dumper($missing8a));

#~ #######################################
#~ Disketo_Utils::logit("fill_requireds");

#~ #my $program9a = Disketo_Preparer::fill_requireds($program1a, $commands);
#~ #print(Dumper($program9a));

#~ my $file9b = "test/scripts/with-requires.ds";
#~ my $script9b = Disketo_Parser::parse($file9b);
#~ my $program9b = Disketo_Analyser::compute_instructions($script9b, $commands);
#~ $program9b = Disketo_Preparer::fill_requireds($program9b, $commands);
#~ print(Dumper($program9b));

#######################################
Disketo_Utils::logit("TODO");

#Disketo_Utils::logit("print_program");
#Disketo_Analyser::print_program($program7a_ref, \@program_args_6a);




