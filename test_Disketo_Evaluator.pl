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
Disketo_Utils::logit("parse_simple");

my $content2a = "foo\tbar\tbaz\nkarel\t42\n";
my $parsed2a_ref = Disketo_Evaluator::parse_simply($content2a);
print Dumper($parsed2a_ref);

my $content2b = "foo_bar_baz\t\"99\tluftbalons\"\t\"333\"\nlorem\t42\tsub { \n\t42;\n }\n";
my $parsed2b_ref = Disketo_Evaluator::parse_simply($content2b);
print Dumper($parsed2b_ref);


#######################################
Disketo_Utils::logit("pseudotokenize");

my @pseudotokens3a_ref = Disketo_Evaluator::pseudotokenize($content2a);
print Dumper(\@pseudotokens3a_ref);
my @pseudotokens3b_ref = Disketo_Evaluator::pseudotokenize($content2b);
print Dumper(\@pseudotokens3b_ref);

