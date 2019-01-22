#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

use DateTime;
use Data::Dumper;
use Disketo_Utils;

#######################################
my @dirs = @ARGV;
list_files(@dirs);

#######################################

sub list_files(@) {
	my @roots = @_;

	Disketo_Utils::logit("Listing files in ". join(", ", @roots) . " ...");
	my %listed = list_all(@roots);

	Disketo_Utils::logit("Found ". (scalar keys %listed) . ", printing them ...");
	print_them(%listed);
}

#######################################

sub list_all(@) {
	my @roots = @_;

	my %result = ();

	for my $root (@roots) {
		my %sub_result = Disketo_Utils::list($root);
		%result = (%result, %sub_result);
	}

	return %result;
}

sub print_them(@) {
	my %result = @_;

	print "$_\n" for (keys %result);
}

