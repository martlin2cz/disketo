#!/usr/bin/perl
use strict;

package Disketo_Utils; 
my $VERSION=0.1;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(go_recursivelly, list);

use DateTime;
use File::stat;
use Data::Dumper;

# Prints the given message to stderr
# in format TIMESTAMP # MESSAGE
sub logit($) {
	my $message = shift @_;

	print STDERR DateTime->now->hms . " # " . $message . "\n";
}


# Lists recursivelly all the subdirectories of given directory 
# and for each it calls the given anonymous function
sub go_recursivelly($&) {
	my $dir = shift @_;
	my $visitor = shift @_;
	
	my $continue = $visitor->($dir);
	if (!$continue) {
		return;
	}

	my $dh;
	unless (opendir($dh, $dir)) {
		print STDERR "Can't open $dir: $!";
		return(1);
	}

	while (my $child = readdir $dh) {
			if (substr($child, 0, 1) eq ".") {
				next;
			}
			
			my $subpath = "$dir/$child";
			if (!(-d $subpath)) {
				next;
			}
			if (!(-r $subpath)) {
				print STDERR "Cannot read $subpath!\n";
				next;
			}
		
			##print "$subpath\n";
			go_recursivelly($subpath, $visitor);
	}

	closedir $dh;
}

# Lists recursivelly all the subdirectories of given directory 
# returns hash mapping for each path the stats object
sub list($) {
	my $dir = shift @_;
	my %result = ();

	my @children = list_children($dir);

	foreach my $child (@children) {
		my $stats = stat($child);
		if (-d $stats) {
			
			my %sub_result = list($child);
			%result = (%result, %sub_result);
		}

		$result{$child} = $stats;
	}

	return %result;		
}	

## Returns array containing all (non-hidden) child resources in given directory
sub list_children($) {
	my $dir = shift @_;

	my @result = ();

	my $dh;
	unless (opendir($dh, $dir)) {
		print STDERR "Can't open $dir: $!\n";
		return @result;
	}

	while (my $child = readdir $dh) {
			if (substr($child, 0, 1) eq ".") {
				next;
			}
			
			my $subpath = "$dir/$child";
			push @result, $subpath;
	}

	closedir $dh;

	return @result;
}




# Prints the list (ref to hash) of files (with stats), 
# with given formatter function
sub print_them($$) {                                                                                                                   
	my %files = %{shift @_};
	my $printer = shift @_;

	print $printer->(\%files{$_}, $_) . "\n" for (keys %files);
}

