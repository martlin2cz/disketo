#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

my $VERSION=3.00.0;

use Disketo_Utils;
use Disketo_Scripter;


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
my $spec = Disketo_Scripter::value_node_specification($program, $node);

print("The \"WTF\" is at position, where $spec is expected.\n");

########################################################################



