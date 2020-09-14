#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

my $VERSION=3.00.0;

use Disketo_Utils;
use Disketo_Scripter;
use List::MoreUtils qw{ firstidx };

########################################################################

Disketo_Utils::check_args(\@ARGV,
	"hint.pl",
	"Disketo statements hint tool",
	"Displays hints for the disketo script statements.",
	"<STATEMENT> or <TOKEN 1> ... [TOKEN n]\n"
	."Place the \"WTF\" (What This Forms?) (with quotes) instead of the identifier/command/value you want, to get help about that.",
	undef, 1);
	
my $statement = join(" ", @ARGV);

my $program = Disketo_Scripter::parse_statement($statement);

my $nodes = Disketo_Preparer::collect_nodes_with_value($program, "WTF");
if (scalar @$nodes > 1) {
	die("Please, specify only one \"WTF\" indicator.");
}
if (scalar @$nodes < 1) {
	print("The statement specified is valid.\n");
	exit;
}

my $node = $nodes->[0];
my $parent = Disketo_Analyser::parent($program, $node);

my $value_name = $node->{"name"};
my $command_name = $parent->{"name"};

my @params = @{ $parent->{"operation"}->{"params"} };
my $param_index = firstidx { $_ eq $node } @params;
my $param_name = $params[$param_index];

print("The \"WTF\" is at position, where the '$value_name' for the '$param_name' parameter of the '$command_name' command is expected.\n");

########################################################################



