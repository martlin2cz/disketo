#!/usr/bin/perl

use strict;

use FindBin qw($Bin); 
use lib "$Bin/../module"; 

use Data::Dumper;
use Disketo_Utils;
use Disketo_Parser;

#######################################
#######################################
Disketo_Utils::logit("load_file");

my $file1 = "$Bin/testing-scripts/simple.ds";
my $content1 = Disketo_Parser::load_file($file1);
print ">>> $content1 <<<\n";

#######################################
Disketo_Utils::logit("parse_content");

my $content2a = "foo " . "lorem \"karel\" " . "ipsum 42\n";
my $parsed2a_ref = Disketo_Parser::parse_content($content2a);
print Dumper($parsed2a_ref);

my $content2b = "foo-bar-baz " . "sample \"99 luftbalons\" \t " . "another-sample \t \"333\"\n"
				. "yet-another-sample\t42 "."subbed-sample\tsub { \n\t\"42\";\n } " . "wild-sample \$\$ " . "## test\n";
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

my @filtered8a = ("whatever", "foo", "sub", "{ 42; }", "bar", "sub{return 1;}", "baz");
my @collapsed8a = Disketo_Parser::collapse_subs(@filtered8a);
print Dumper(\@collapsed8a);

#######################################
Disketo_Utils::logit("parse");
my ($script7a_ref) = Disketo_Parser::parse($file1);
print Dumper($script7a_ref);

