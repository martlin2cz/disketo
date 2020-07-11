#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

use Data::Dumper;
use Disketo_Instruction_Set;

########################################################################

print(Dumper(Disketo_Instruction_Set::instructions()));
