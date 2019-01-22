#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

use DateTime;
use Data::Dumper;
use Disketo_Utils;

#######################################
my $size_unit = shift @ARGV;
my @dirs = @ARGV;

list_files($size_unit, @dirs);

#######################################

sub list_files(@) {
	my $size_unit = shift @_;
	my @roots = @_;

	Disketo_Utils::logit("Listing files in ". join(", ", @roots) . " ...");
	my %listed = list_all(@roots);

	Disketo_Utils::logit("Found ". (scalar keys %listed) . ", printing them with size in $size_unit ...");
	print_them_formatted(\%listed, $size_unit);
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

sub print_them_formatted($$) {
	my %files = %{shift @_};
	my $size_unit = shift @_;
	
	my $printer = sub { 
		my $file = ${ shift @_ };
		my $stats = ${ shift @_ };
		my $size = $stats->size;

		if (uc($size_unit) eq "B") {
			return "$file \t " . $size;
		} elsif (uc($size_unit) eq "KB") {
			return "$file \t " . $size / (10 ** 3);
		} elsif (uc($size_unit) eq "MB") {
			return "$file \t " . $size / (10 ** 6);
		} elsif (uc($size_unit) eq "GB") {
			return "$file \t " . $size / (10 ** 9);
		} elsif (uc($size_unit) eq "TB") {
			return "$file \t " . $size / (10 ** 12);
		} else {
			return "$file";
		}
	};

	Disketo_Utils::print_them(\%files, $printer);
}
