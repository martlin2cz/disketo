#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

package Disketo_IO;
my $VERSION=3.00.0;

use Data::Dumper;
use File::Basename;
#use File::stat;
use Disketo_Utils;

########################################################################
# The Input/Output module for the Disketo. In fact, just wrapper for the
# native system IO (in terms of files, dirs, metadatas, stats, sizes, dates, ...).
########################################################################
# LOAD

# Lists either the all the directories if the $ is directory,
# or simply loads the listed resources from the $ text file.
# Fails otherwise.
sub list($) {
	my ($dir_or_file) = @_;

	if (-d $dir_or_file) {
		return list_directory($dir_or_file, 0);
	}
	if (-f $dir_or_file) {
		return list_from_file($dir_or_file);
	}

	die("Nor directory or file: $dir_or_file ")	
}

# Lists recursivelly all the subdirectories of given directory 
# returns ref to hash mapping for each path the directory children.
sub list_directory($) {
	my ($dir, $previous_count) = @_;
	my %result = ();
	my $count = $previous_count;

	my $children_ref = children_of($dir);
	my @children = @{ $children_ref };
	$result{$dir} = $children_ref;
	
	foreach my $child (@children) {
		if (-d $child) {
			my %sub_result = %{ list_directory($child, $count) };

			%result = (%result, %sub_result);		
			$count += scalar %sub_result;

			Disketo_Utils::check_progress($count, undef);
		}
	}

	return \%result;		
}	

# Lists all the paths from the given file. Assuming absolute paths
# and one at each line.
sub list_from_file($) {
	my ($file) = @_;
	
	my $lines_ref = load_lines($file);
	return files_to_dirs($lines_ref);
}

# Returns ref to array containing all (non-hidden) child resources 
# in given directory
# Note: internal function
sub children_of($) {
	my ($dir) = @_;

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

	return \@result;
}
# For given input file loads all its lines
sub load_lines($) {
	my ($file) = @_;

	my $handle;
	unless(open $handle, '<:encoding(utf8)', $file) {
		print STDERR "Can't open $file: $!\n";
		return \{}
	}
	chomp(my @lines = <$handle>);
	close $handle;

	return \@lines;
}

# For given input lines (representing the files paths) list ref
# creates ref to hash with their dirs.
sub files_to_dirs($) {
	my @files = @{ shift @_ };
	my %result = ();

	for my $file (@files) {
		my $parent = dirname($file);
		push @{ $result{$parent} }, $file;

		Disketo_Utils::check_progress(scalar %result, undef);
	}

	return \%result;
}

# For given input dirs ref loads their stats
# Returns both (ref to %dirs and ref to %stats)
sub load_stats($) {
	my %dirs = %{ shift @_ };

	my %stats = ();
	#for my $dir (keys %dirs) {
	Disketo_Utils::iterate([keys %dirs], sub($$) {
		my ($dir, $i) = @_;

		my @children = @{%dirs{$dir}};
		my %stat = map { $_ => stat($_) } @children;
		%stats = (%stats, %stat);
	});

	return (\%dirs, \%stats);
}

########################################################################
# STATS

sub load_stats_for_file($) {
	my ($file) = @_;
	
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
		$atime,$mtime,$ctime,$blksize,$blocks) = stat($file);
	
	return {
		# "file" => $file,
		"mode" => $mode,
		"user-id" => $uid,
		"size" => $size,
		"last-access" => $atime,
		"last-modify" => $mtime,
	};
}

########################################################################
# FILE SIZE

#TODO file size to human format

