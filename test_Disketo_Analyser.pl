#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

use Data::Dumper;
use Disketo_Utils;
use Disketo_Parser;
use Disketo_Analyser;
use Disketo_Instruction_Set;

#######################################
Disketo_Utils::logit("(parsing the file)");
my $file1a = "test/scripts/simple.ds";
my $script1a = Disketo_Parser::parse($file1a);

#######################################
Disketo_Utils::logit("(commands)");
my $commands = Disketo_Instruction_Set::commands();

#######################################
Disketo_Utils::logit("tree_usage");

print(Disketo_Analyser::tree_usage());

#~ #######################################
#~ Disketo_Utils::logit("linear_usage");

#~ print(join("\n", @{ Disketo_Analyser::linear_usage() }));

#######################################
Disketo_Utils::logit("compute_instruction");

my $statement6a = ["compute", "for-each-dir", "count-files"];
my $tree6a = Disketo_Analyser::compute_instruction($statement6a, $commands);
print(Dumper($tree6a));

my $statement6b = ["compute", "for-each-file", "custom", "sub {...}", "\"the new meta\""];
my $tree6b = Disketo_Analyser::compute_instruction($statement6b, $commands);
print(Dumper($tree6b));

#######################################
Disketo_Utils::logit("print_syntax_tree");
Disketo_Analyser::print_syntax_tree($tree6a);
Disketo_Analyser::print_syntax_tree($tree6b);

#######################################
Disketo_Utils::logit("compute_instructions");
my $program7a = Disketo_Analyser::compute_instructions($script1a, $commands);
print(Dumper($program7a));

#######################################
#######################################
Disketo_Utils::logit("find_missing_required_metas");

my $command8a = {"requires" => ["foo meta", "bar meta", "lorem meta"]};
my $produced8a = ["lorem meta", "ipsum meta"];
my $missing8a = Disketo_Analyser::find_missing_required_metas($command8a, $produced8a);
print(Dumper($missing8a));

#######################################
Disketo_Utils::logit("fill_requireds");

my $program9a = Disketo_Analyser::fill_requireds($program7a, $commands);
print(Dumper($program9a));

my $file9b = "test/scripts/with-requires.ds";
my $script9b = Disketo_Parser::parse($file9b);
my $program9b = Disketo_Analyser::compute_instructions($script9b, $commands);
$program9b = Disketo_Analyser::fill_requireds($program9b, $commands);
print(Dumper($program9b));

#######################################
Disketo_Utils::logit("TODO");

#Disketo_Utils::logit("print_program");
#Disketo_Analyser::print_program($program7a_ref, \@program_args_6a);




