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
	
	print STDERR DateTime->now->hms . " # Listing directories in ". join(", ", @roots) . " ...\n";	
	my @dirs = list(@roots);
	
	print STDERR DateTime->now->hms . " # Found totally " . scalar @dirs . ", filtering them against $pattern ...\n";
	@dirs = filter($pattern, @dirs);
	
	print STDERR DateTime->now->hms . " # Filtered, currently " . scalar @dirs . ", matching duplicite names ...\n";
	my %matches = match_duplicite_names(@dirs);

	print STDERR DateTime->now->hms . " # Matched  " . scalar %matches . " directories. Printing them:\n";
	print $_ . "\t=>\t(" . scalar @{ $matches{$_} } . ")\t" . "@{ $matches{$_} }" . "\n" for (keys %matches);
}

#######################################

sub list(@) {
	my @roots = @_;

	my @results = ();
	for my $root (@roots) {
		Disketo_Utils::go_recursivelly($root, sub() {
			my $dir = @_[0];
			push @results, $dir;
			return 1;
		});
	}
	
	return @results;
}

#######################################

sub filter($@) {
	my $pattern = shift @_;
	my @dirs = @_;
	my @result = ();

	for my $dir (@dirs) {
		opendir(my $dh, $dir) || do {
			print STDERR "Can't open $dir: $! !";
			next;
		};
		my @children = readdir $dh;
		closedir $dh;

		my @matching = grep(/$pattern/, @children);
		if (@matching) {
			push @result, $dir;
		}
	}

	return @result;
}

#######################################

sub match_duplicite_names(@) {
  my @dirs = @_;

	my %results = ();
	for my $left_dir (@dirs) {
		my $name = $left_dir;
		$name = (split(/\//, $left_dir))[-1];
		my @matching = grep (/\Q$name\E\/?$/, @dirs);
		my $count = scalar @matching;
		
		if ($count > 1) {
			push @{ $results{$left_dir} }, @matching;
		}
	}

	return %results;
}

