#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

use Data::Dumper;
use List::Util;
use Disketo_Utils;

use Disketo_Engine;

use Disketo_Instructions;


#######################################

my $context = Disketo_Engine::create_context();
my $roots = ["test/dolor", "test/ipsum", "test/lsof.txt"];

# TODO possibly in the future ...

Disketo_Engine::context_stats($context);
