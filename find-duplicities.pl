#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

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
	
	print STDERR "Listing directories in ". join(", ", @roots) . " ...\n";	
	my @dirs = list(@roots);
	
	print STDERR "Found totally " . scalar @dirs . ", filtering them against $pattern ...\n";
	@dirs = filter($pattern, @dirs);
	
	print STDERR "Filtered, currently " . scalar @dirs . ", matching duplicities ...\n";
	my %dirs = match_duplicities(@dirs);

	print STDERR "Matched  " . scalar %dirs . " directories.\n";
	print ($_ . "\n") for each (%dirs);

}

#######################################

sub list(@) {
	my @roots = @_;

	my @results = ();
	for my $root (@roots) {
		Disketo_Utils::go_recursivelly($root, sub() {
			my $dir = @_[0];
			push @results, $dir;
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
		opendir(my $dh, $dir) || die "Can't open $dir: $!";
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

sub match_duplicities(@) {
  my @dirs = @_;

	my %results = ();
	for my $left_dir (@dirs) {
		opendir(my $ldh, $left_dir) || die "Can't open $left_dir: $!";
		my @left_children = readdir $ldh;
		closedir $ldh;

		for my $right_dir (@dirs) {
			if ($left_dir eq $right_dir) {
				next;
			}

			opendir(my $rdh, $right_dir) || die "Can't open $right_dir: $!";
			my @right_children = readdir $rdh;
			closedir $rdh;
	
			my @intersect = intersect(\@left_children, \@right_children);
			if (scalar @intersect > INTERSECT_RATIO) {
				$results{$left_dir} = $right_dir;
			}
		}
	}

	return %results;
}

#######################################
#######################################

sub intersect(\@\@) {
	## https://perlmaven.com/passing-two-arrays-to-a-function
	my ($left_ref, $right_ref) = @_;
	my @left = @{ $left_ref };
	my @right = @{ $right_ref };

	my %intersects = ();
	## https://stackoverflow.com/questions/7842114/get-the-intersection-of-two-lists-of-strings-in-perl
	foreach my $item (@left, @right) {
		$intersects{$item}++
	}

	my @intersects = keys %intersects;
	return @intersects;
}


