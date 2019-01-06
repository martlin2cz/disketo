#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

use Disketo_Utils;

Disketo_Utils::print_tree(shift @ARGV);



