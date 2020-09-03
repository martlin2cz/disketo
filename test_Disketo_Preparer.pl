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

#######################################
Disketo_Utils::logit("(commands)");
my $commands = Disketo_Instruction_Set::commands();

#TODO

#######################################
#######################################
Disketo_Utils::logit("find_missing_required_metas");

my $command8a = {"requires" => ["foo meta", "bar meta", "lorem meta"]};
my $produced8a = ["lorem meta", "ipsum meta"];
my $missing8a = Disketo_Preparer::find_missing_required_metas($command8a, $produced8a);
print(Dumper($missing8a));

#######################################
Disketo_Utils::logit("fill_requireds");

my $program9a = Disketo_Preparer::fill_requireds($program1a, $commands);
print(Dumper($program9a));

my $file9b = "test/scripts/with-requires.ds";
my $script9b = Disketo_Parser::parse($file9b);
my $program9b = Disketo_Analyser::compute_instructions($script9b, $commands);
$program9b = Disketo_Preparer::fill_requireds($program9b, $commands);
print(Dumper($program9b));

#######################################
Disketo_Utils::logit("TODO");

#Disketo_Utils::logit("print_program");
#Disketo_Analyser::print_program($program7a_ref, \@program_args_6a);




