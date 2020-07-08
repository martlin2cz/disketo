#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

use Data::Dumper;
use List::Util;
use Disketo_Utils;


#######################################
#######################################

Disketo_Utils::logit("This is just an message.");

#######################################

Disketo_Utils::log_entry("Task 1 starting");
Disketo_Utils::log_entry("Subtask 1.1 starting");
Disketo_Utils::log_entry("Subsubtask 1.1.1 starting");
# subsubtask 1.1.1
Disketo_Utils::log_exit("Subsubtask 1.1.1 completed");
Disketo_Utils::log_entry("Subsubtask 1.1.2 starting");
# subsubtask 1.1.2
Disketo_Utils::log_exit("Subsubtask 1.1.2 completed");
Disketo_Utils::log_exit("Subsubtask 1.1 completed");
Disketo_Utils::log_entry("Subtask 1.2 starting");
# subtask 1.2
Disketo_Utils::log_exit("Subtask 1.2 completed");
Disketo_Utils::log_entry("Subtask 1.3 starting");
# subtask 1.3
Disketo_Utils::log_exit("Subtask 1.3 completed");
Disketo_Utils::log_exit("Task 1 completed");
Disketo_Utils::log_entry("Task 2 starting");
# task 2
Disketo_Utils::log_exit("Task 2 completed");
Disketo_Utils::log_entry("Task 3 starting");
# task 3
Disketo_Utils::log_exit("Task 3 completed");









#
