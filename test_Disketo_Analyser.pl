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
Disketo_Utils::logit("compute_instruction");

my $statement6a = ["compute", "for-each-dir", "count-files"];
my $tree6a = Disketo_Analyser::compute_instruction($statement6a, 0, $commands);
print(Dumper($tree6a));

my $statement6b = ["compute", "for-each-file", "custom", "\"the new meta\"", "sub {...}"];
my $tree6b = Disketo_Analyser::compute_instruction($statement6b, 0, $commands);
print(Dumper($tree6b));

my $statement6c = ["filter", "dirs", "having-files", "more-than", "5", "matching-pattern", "\"test_(.*)\"", "case-insensitive"];
my $tree6c = Disketo_Analyser::compute_instruction($statement6c, 0, $commands);
print(Dumper($tree6c));

#######################################
Disketo_Utils::logit("walk_tree");
Disketo_Analyser::walk_tree($tree6b, "B", 
	sub { 
		my ($node, $stack, $param_name, $name, $operation, $params, $arguments) = @_;
		print("($name)\n");
	},
	sub { 
		my ($node, $stack, $param_name, $name, $value, $prepared_value, $resolved_value) = @_;
		print("- $name -> $value\n");
	});

#######################################
Disketo_Utils::logit("print_syntax_tree");
Disketo_Analyser::print_syntax_tree($tree6a, "A");
Disketo_Analyser::print_syntax_tree($tree6b, "B");
Disketo_Analyser::print_syntax_tree($tree6c, "C");

#######################################
Disketo_Utils::logit("compute_instructions");
my $program7a = Disketo_Analyser::compute_instructions($script1a, $commands);
print(Dumper($program7a));

Disketo_Analyser::print_syntax_forrest($program7a);

#######################################
#######################################
Disketo_Utils::logit("parent");
my $node8a = $program7a->[1]->{"arguments"}->[0]->{"arguments"}->[0]->{"arguments"}->[0];
print(Dumper($node8a));
my $node8b = Disketo_Analyser::parent($program7a, $node8a);
print(Dumper($node8b));

#######################################
#######################################

