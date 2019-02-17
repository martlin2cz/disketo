#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

use Data::Dumper;
use Disketo_Utils;
use Disketo_Evaluator;


#######################################
#######################################
Disketo_Utils::logit("load_file");

my $file1 = "test/lorem/foo/file-2.txt";
my $content1 = Disketo_Evaluator::load_file($file1);
print ">>> $content1 <<<\n";

#######################################
Disketo_Utils::logit("parse_content");

my $content2a = "foo bar baz karel 42\n";
my $parsed2a_ref = Disketo_Evaluator::parse_content($content2a);
print Dumper($parsed2a_ref);

my $content2b = "foo_bar_baz \"99 luftbalons\" \t \"333\"\nlorem\t42\tsub { \n\t\"42\";\n } \$\$ ## test\n";
my $parsed2b_ref = Disketo_Evaluator::parse_content($content2b);
print Dumper($parsed2b_ref);


#######################################
Disketo_Utils::logit("tokenize");

my @tokens3a_ref = Disketo_Evaluator::tokenize($content2a);
print Dumper(\@tokens3a_ref);
my @tokens3b_ref = Disketo_Evaluator::tokenize($content2b);
print Dumper(\@tokens3b_ref);

#######################################
Disketo_Utils::logit("collapse_subs");

my @filtered8a = ("foo", "sub", "{ 42; }", "bar", "sub{return 1;}", "baz");
my @collapsed8a = Disketo_Evaluator::collapse_subs(@filtered8a);
print Dumper(\@collapsed8a);



#######################################
Disketo_Utils::logit("functions_table");
my $table4_ref = Disketo_Evaluator::functions_table();
print Dumper($table4_ref);

#######################################
Disketo_Utils::logit("validate_function");
my @statement5a = ("filter_directories_matching", "42", "karel");
my ($statement5a_mod_ref, $fnname5a, $function5a_ref) = Disketo_Evaluator::validate_function(\@statement5a, $table4_ref);
print Dumper($statement5a_mod_ref, $fnname5a, $function5a_ref);

my @statement5b = ("foo_bar_baz", "lorem", "ipsum");
### Disketo_Evaluator::validate_function(\@statement5b, $table4_ref);

#######################################
Disketo_Utils::logit("validate_params");
my @statement6a_mod = ("42", "karel", "\$\$", "\"boo\"", "sub { 99; }");
my @program_args_6a = ("foo", "bar", "baz");
my %function6 = ( "method" => &Disketo_Utils::logit, "params" => ["first", "second", "third", "fourth", "fifth"] );

my ($resolved_args6) = Disketo_Evaluator::validate_params(\@statement6a_mod, $fnname5a, \%function6);
print Dumper($resolved_args6);

my @statement6b_mod = ("foo", "bar", "baz", "42");
### Disketo_Evaluator::validate_params(\@statement6b_mod, $fnname5a, \%function6);

my @statement6b_mod = ("\$\$", "\$\$", "\$\$", "\$\$", "\$\$");
### Disketo_Evaluator::validate_params(\@statement6b_mod, $fnname5a, \%function6);

#######################################
Disketo_Utils::logit("parse");
my $script7a = "test/scripts/simple.ds";
my ($program7a_ref) = Disketo_Evaluator::parse($script7a);
print Dumper($program7a_ref);

#######################################
Disketo_Utils::logit("print_usage");
my @arguments8a = ("foo");
### Disketo_Evaluator::print_usage($script7a, $program7a_ref, \@arguments8a);

#######################################
Disketo_Utils::logit("print_program");
Disketo_Evaluator::print_program($program7a_ref, \@program_args_6a);

#######################################
Disketo_Utils::logit("prepare");
my ($prepared10_ref) = Disketo_Evaluator::prepare($program7a_ref, \@program_args_6a);
print Dumper($prepared10_ref);



