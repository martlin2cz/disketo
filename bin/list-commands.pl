#!/usr/bin/perl

use strict;
my $VERSION=3.00.0;

use FindBin qw($Bin); 
use lib "$Bin/../module"; 

use Disketo_Utils;
use Disketo_Scripter;

########################################################################

Disketo_Utils::check_args(\@ARGV,
	"list-commands.pl",
	"List of disketo commands",
	"Displays list (table, tree) of all the disketo commands and their parameters.",
	"(no arguments required)",
	0, undef);
	
#TODO add support for context specific subtree
	
Disketo_Scripter::print_commands_tree();

########################################################################



