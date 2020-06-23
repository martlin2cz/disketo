#!/usr/bin/perl
use strict;

package Disketo_Utils; 
my $VERSION=0.2;
use constant PROGRESS_PERIOD => 60;

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
# The last time progress have been printed
my $last_printed_at = 0;

#############################################################
# Iterates over the given array, applying given function;
# each PROGRESS_PERIOD seconds prints percentage of done.
sub iterate($$) {
	my @array = @{ shift @_ };
	my $function_ref = shift @_;

	my $total = scalar @array;
	my @result = ();

	print_progress(0, $total);
	my $last_printed_at = time();
	
	for (my $i = 0; $i < $total; $i++) {
		my $item = $array[$i];
		my $subresult = $function_ref->($item, $i, \@result);
		if ($subresult) {
			push @result, $subresult;
		}
		
		check_progress($i, $total);
	}

	return \@result;
}
#############################################################
# If more than PROGRESS_PERIOD since last print_progress, 
# prints_progress with given i (and total).
sub check_progress($$) {
	my ($i, $total) = @_;

	my $now_at = time();
	if ($now_at - $last_printed_at > PROGRESS_PERIOD) {
	
		print_progress($i, $total);
	
		$last_printed_at = $now_at;
	}
}
############################################################
# Prints given i out of total as a percentage 
# or only i if total is none
sub print_progress($$) {
	my ($i, $total) = @_;
	
	if ($total) {
		my $percent = ($i * 100.0) / $total;
		printf (STDERR "\t%4.2g%% \r", $percent);
	} else {
		printf (STDERR "\t%d \r", $i); 
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
