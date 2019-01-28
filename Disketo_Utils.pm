#!/usr/bin/perl
use strict;

package Disketo_Utils; 
my $VERSION=0.1;

use DateTime;
use Data::Dumper;

#############################################################
# Prints the given message to stderr
# in format TIMESTAMP # MESSAGE
sub logit($) {
	my $message = shift @_;

	print STDERR DateTime->now->hms . " # " . $message . "\n";
}


#############################################################
#############################################################
#############################################################
# Intersects given two array refs by given equality fn
sub intersect($$$) {
	my @left = @{ shift @_ };
	my @right = @{ shift @_ };
	my $matcher = shift @_ ;

	my %result = ();
	
	for my $left (@left) {
		for my $right (@right) {
			my $match = $matcher->($left, $right);
			if ($match) {
				push @{ $result{$left} }, $right;
			}
		}
	}

	return \%result;
}
