#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

use DateTime;
use Disketo_Utils;
#######################################
sub INTERSECT_RATIO { 5 }
#######################################
my $pattern = shift @ARGV;
my @dirs = @ARGV;
find_duplicities($pattern, @dirs);

#######################################

sub find_duplicities($@) {
	my $pattern = shift @_;
	my @roots = @_;
	
	print STDERR DateTime->now->hms . " # Listing directories in ". join(", ", @roots) . " and filtering agains $pattern ...\n";	
	my @dirs = list_and_filter($pattern, @roots);
	
	print STDERR DateTime->now->hms . " # Done, there is " . scalar @dirs . " of them, printing:\n";
	print "$_\n" foreach (@dirs);
}

#######################################

sub list_and_filter($@) {
	my $pattern = shift @_;
	my @roots = @_;
	my @result = ();

	my @results = ();
	for my $root (@roots) {
		Disketo_Utils::go_recursivelly($root, sub() {
			my $dir = @_[0];
			
			if ($dir =~ /$pattern/) {
				push @results, $dir;
				return 0;
			}

			return 1;
		});
	}
	
	return @results;
}

#######################################

