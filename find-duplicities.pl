#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

use DateTime;
use Data::Dumper;
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
	my %dirs = filter($pattern, @dirs);
	
	print STDERR DateTime->now->hms . " # Filtered, currently " . (scalar keys %dirs) . ", matching duplicities ...\n";
	%dirs = match_duplicities(%dirs);

	print STDERR DateTime->now->hms . " # Matched  " . scalar %dirs . " directories. Printing them:\n";
		print "$_ \t ~ \t $dirs{$_}{'right_dir'} \t"
			. " " . (scalar @{$dirs{$_}{'left_children'}}) . " / " . (scalar @{$dirs{$_}{'left_children'}}) . " \t"
			. " $dirs{$_}{'left_ratio'}% / $dirs{$_}{'right_ratio'}% \t \t"
			. " @{$dirs{$_}{'intersection'}} \n" for (keys %dirs);  

	##print Dumper(%dirs);
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
	my %result = ();

	for my $dir (@dirs) {
		opendir(my $dh, $dir) || do {
			print STDERR "Can't open $dir: $! !";
			next;
		};
		my @children = readdir $dh;
		closedir $dh;

		my @matching = grep(/$pattern/, @children);
		if (@matching) {
			push @{ $result{$dir} }, @children;
		}
	}

	return %result;
}

#######################################

sub match_duplicities(%) {
  my %dirs = @_;

	my %results = ();
	for my $left_dir (keys %dirs) {
		my @left_children = @{ $dirs{$left_dir} };

		for my $right_dir (keys %dirs) {
			if ($left_dir eq $right_dir) {
				next;
			}
			my @right_children = @{ $dirs{$right_dir} };
	
			my @intersect = intersect(\@left_children, \@right_children);
			## print "$left_dir X $right_dir -> @intersect\n";
			if (scalar @intersect > INTERSECT_RATIO) {
				$results{$left_dir} = {
					"left_dir" => $left_dir,
					"right_dir" => $right_dir,
					"left_children" => \@left_children,
					"right_children" =>\ @right_children,
					"intersection" => \@intersect,
					"left_ratio" => (scalar @intersect) / (scalar @left_children) * 100,
					"right_ratio" => (scalar @intersect) / (scalar @right_children) * 100
				}
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

	##my %intersects = ();
	#### https://stackoverflow.com/questions/7842114/get-the-intersection-of-two-lists-of-strings-in-perl
	##foreach my $item (@left, @right) {
	##	$intersects{$item}++;
	##}

	##my @intersects = keys %intersects;
	
	## http://www.chovy.com/perl/finding-an-intersection-between-arrays-in-perl/
	my %original;
	map { $original{$_} = 1 } @left;
	my @intersects = grep { $original{$_} } @right;
	
	## print "A: @left \t B: @right \t AND: @intersects\n\n";
	return @intersects;
}


