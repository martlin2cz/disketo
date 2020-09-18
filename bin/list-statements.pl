#!/usr/bin/perl

use strict;
my $VERSION=3.00.0;

use FindBin qw($Bin); 
use lib "$Bin/../module"; 

use Disketo_Utils;
use Disketo_Scripter;

########################################################################

Disketo_Utils::check_args(\@ARGV,
	"list-statements.pl",
	"List of disketo statements",
	"Displays list of all the possible disketo script statements.",
	"(no arguments required)",
	0, undef);
	
#TODO add support for context specific subtree
	
Disketo_Scripter::print_all_statements();

########################################################################



