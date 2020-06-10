#!/usr/bin/perl
use strict;

package Disketo_Utils; 
my $VERSION=0.1;

use DateTime;
use Data::Dumper;


#############################################################
# Prints specified info about app arguments
# if no args given
# and dies
sub usage($$) {
	my $ARGV_ref = shift @_;
	my $info = shift @_;

	if (scalar @{ $ARGV_ref } == 0) {
		my $cmd = $0;

		die("Usage: $cmd $info\n");
	}
}



#############################################################
# Prints the given message to stderr
# in format TIMESTAMP # MESSAGE
sub logit($) {
	my $message = shift @_;

	print STDERR DateTime->now->hms . " # " . $message . "\n";
}

#############################################################
# The currrent entered level
my $entereds = 0;

#############################################################
# Prints the given message to stderr
# if not yet any other entered 
# but not-existed printed
sub log_entry($) {
	my $message = shift @_;
	
	if ($entereds < 1) {
		logit($message);
	}

	$entereds++;
}

#############################################################
# Prints the given message to stderr
# if no more than one others entered
# in format TIMESTAMP # MESSAGE
sub log_exit($) {
	my $message = shift @_;
	
	$entereds--;
	if ($entereds < 1) {
		logit($message);
	}
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


return 1;
