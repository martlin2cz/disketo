#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

use Data::Dumper;
use Disketo_Utils;
use Disketo_Parser;

#######################################
#######################################
Disketo_Utils::logit("load_file");

my $file1 = "test/lorem/foo/file-2.txt";
my $content1 = Disketo_Parser::load_file($file1);
print ">>> $content1 <<<\n";

#######################################
Disketo_Utils::logit("parse_content");

my $content2a = "foo bar baz karel 42\n";
my $parsed2a_ref = Disketo_Parser::parse_content($content2a);
print Dumper($parsed2a_ref);

my $content2b = "foo_bar_baz \"99 luftbalons\" \t \"333\"\nlorem\t42\tsub { \n\t\"42\";\n } \$\$ ## test\n";
my $parsed2b_ref = Disketo_Parser::parse_content($content2b);
print Dumper($parsed2b_ref);


#######################################
Disketo_Utils::logit("tokenize");

my @tokens3a_ref = Disketo_Parser::tokenize($content2a);
print Dumper(\@tokens3a_ref);
my @tokens3b_ref = Disketo_Parser::tokenize($content2b);
print Dumper(\@tokens3b_ref);

#######################################
Disketo_Utils::logit("collapse_subs");

my @filtered8a = ("foo", "sub", "{ 42; }", "bar", "sub{return 1;}", "baz");
my @collapsed8a = Disketo_Parser::collapse_subs(@filtered8a);
print Dumper(\@collapsed8a);

#######################################
Disketo_Utils::logit("parse");
my $script7a = "test/scripts/simple.ds";
my ($program7a_ref) = Disketo_Parser::parse($script7a);
print Dumper($program7a_ref);

