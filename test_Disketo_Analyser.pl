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
Disketo_Utils::logit("extract");

my $statement4a = ["filter_dirs_matching_pattern", "42", "karel"];
my ($command_name4a, $arguments4a) = Disketo_Analyser::extract($statement4a);
print(Dumper($command_name4a, $arguments4a));

my $statement4b = ["foo_bar_baz", "lorem", "ipsum"];
my ($command_name4b, $arguments4b) = Disketo_Analyser::extract($statement4b);
print(Dumper($command_name4b, $arguments4b));
#######################################
Disketo_Utils::logit("validate_command_name");

my $command_name5a = "filter_dirs_matching_pattern";
my ($command5a) = Disketo_Analyser::validate_command_name($command_name5a, $commands);
print Dumper($command5a);

my $command_name5b = "foo_bar_baz";
### Disketo_Analyser::validate_command_name($command_name5b, $commands);
print("skipped because would die\n");

#######################################
Disketo_Utils::logit("validate_command_params");

my $arguments6a = ["foo+"];
my ($params6) = Disketo_Analyser::validate_command_params($arguments6a, $command5a);
print Dumper($params6);

my $arguments6b = ["foo", "bar"];
### Disketo_Analyser::validate_command_params($arguments6b, $command5a);
print("skipped because would die\n");

my $arguments6c = [];
### Disketo_Analyser::validate_command_params($arguments6c, $command5a);
print("skipped because would die\n");

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




