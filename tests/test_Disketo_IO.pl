#!/usr/bin/perl

use strict;

use FindBin qw($Bin); 
use lib "$Bin/../module"; 

use Data::Dumper;
use Disketo_Utils;
use Disketo_IO;

#######################################
Disketo_Utils::logit("size_to_human_readable");

print(Disketo_IO::size_to_human_readable(0)."\n");
print(Disketo_IO::size_to_human_readable(110)."\n");
print(Disketo_IO::size_to_human_readable(1549)."\n");
print(Disketo_IO::size_to_human_readable(5458647)."\n");
print(Disketo_IO::size_to_human_readable(546786421213212)."\n");
#######################################

#TODO somewhere in the future ...
