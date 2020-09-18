#!/usr/bin/perl

use strict;

use FindBin qw($Bin); 
use lib "$Bin/../module"; 

use Data::Dumper;
use Disketo_Instruction_Set;

########################################################################

print(Dumper(Disketo_Instruction_Set::commands()));
