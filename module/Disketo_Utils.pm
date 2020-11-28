#!/usr/bin/perl
use strict;

package Disketo_Utils; 
my $VERSION=3.1.0;

# The version to be printed by --version.
use constant VERSION => "3.1.0";

# How offten (in seconds) tu print the current orogress?
use constant PROGRESS_PERIOD => 10;

use DateTime;
use Data::Dumper;

########################################################################
# Implements all the general utilities for the whole application.
########################################################################

########################################################################
# ARGS

# Checks whether the given ARGS matches the specific criteria and prints
# particular output if yes.
# In particular, checks whether the ARGS has the help or version flag. 
# If so, by help of program_command, program_name, program_description 
# and parameters_explanation and VERSION prints so.
# Otherwise checks whether ARGS has required_args_count or required_min_args_count
# (only one of them can be specified).
sub check_args($$$$$$$) {
	my ($ARGV, $program_command, $program_name, 
		$program_description, $parameters_explanation,
		$required_args_count, $required_min_args_count) = @_;
	
	check_help($ARGV, $program_command, $program_name, $program_description, $parameters_explanation);
	check_version($ARGV, $program_name);
	check_actual_args($ARGV, $program_command, $parameters_explanation, $required_args_count, $required_min_args_count);
}

# Checks whether the given ARGV has the help flag and if so,
# prints the help and usage and dies.
sub check_help($$$$) {
	my ($ARGV, $program_command, $program_name, $program_description, $parameters_explanation) = @_;
	
	if (scalar @$ARGV != 1) {
		return;
	}
	
	if (not ($ARGV->[0] eq "-h") and not ($ARGV->[0] eq "--help")) {
		return;
	}
	
	print("$program_name\n");
	print("$program_description\n");
	print("Usage $program_command $parameters_explanation\n");
	die("\n");

}

# Checks whether the given ARGV has the version flag and if so,
# prints the version and dies.
sub check_version($$) {
	my ($ARGV, $program_name) = @_;

	if (scalar @$ARGV != 1) {
		return;
	}
	
	if (not ($ARGV->[0] eq "-v") and not ($ARGV->[0] eq "--version")) {
		return;
	}
	
	print("$program_name " . VERSION . "\n");
	die("\n");
}	

# Checks whether the given ARGV has the specified args counts and if not,
# dies with the error message and usage.
sub check_actual_args($$$) {
	my ($ARGV, $program_command, $parameters_explanation, $required_args_count, $required_min_args_count) = @_;
	my $count = scalar @$ARGV;
	
	if (defined($required_args_count)) {
		if ($required_args_count == $count) {
			return;
		} else {
			print STDERR ("Expected $required_args_count arguments, given $count.\n");
		}
	}

	if (defined($required_min_args_count)) {
		if ($required_min_args_count <= $count) {
			return;
		} else {
			print STDERR ("Expected at least $required_min_args_count arguments, given $count.\n");
		}	
	}
	
	print STDERR ("Usage $program_command $parameters_explanation\n");
	die("\n");
}

#############################################################
# Prints the given message to stderr
# in format TIMESTAMP # MESSAGE
sub logit($) {
	my $message = shift @_;

	print STDERR DateTime->now->hms . " # " . $message . "\n";
}

########################################################################
# PRINT PROGRESS

# Walk ordered, directory first (preorder)
our $ORDER_DIR_FIRST = "ORDER DIRECTORY FIRST";
# Walk ordered, directory last (postorder)
our $ORDER_DIR_LAST = "ORDER DIRECTORY LAST";
# Walk unordered (in random, unspecified order)
our $UNORDERED = "UNORDERED";

# The last time progress have been printed
my $last_printed_at = 0;
my $loop_started_at = 0;

# Iterates over the context's dirs, applying given function;
# each PROGRESS_PERIOD seconds prints percentage of done.
sub iterate_dirs($$$) {
	my ($context, $order, $function_ref) = @_;
	
	my @dirs = keys %{ $context->{"resources"} };
	my $ordered = order_list(\@dirs, $order);
	my $total = scalar @$ordered;

	start_progress($total);
	
	for (my $i = 0; $i < $total; $i++) {
		my $dir = $ordered->[$i];

		$function_ref->($dir, $i);
		
		check_progress($i, $total);
	}
}

# Iterates over the context's files, applying given function;
# each PROGRESS_PERIOD seconds prints percentage of done.
sub iterate_files($$$) {
	my ($context, $order, $function_ref) = @_;
	my %resources = %{ $context->{"resources"} };
	my @dirs = keys %resources;
	my $ordered_dirs = order_list(\@dirs, $order);
	
	my $total = scalar @$ordered_dirs;
	start_progress($total);
	
	for (my $i = 0; $i < $total; $i++) {
		my $dir = $ordered_dirs->[$i];
		
		my @files = @{ %resources{$dir} };
		my $ordered_files = order_list(\@files, $order);
		my $files_count = scalar @$ordered_files;
		
		for (my $j = 0; $j < $files_count; $j++) {
			my $file = $ordered_files->[$j];
			$function_ref->($dir, $i, $file, $j);
		}
		
		check_progress($i, $total);
	}
}

# Orders the given resources by dir first or last or keeps it as it is.
sub order_list($$) {
	my ($resources, $order) = @_;
	
	if ($order eq $ORDER_DIR_FIRST) {
		my @ordered = sort @$resources;
		return \@ordered;
	}
	if ($order eq $ORDER_DIR_LAST) {
		my @ordered = reverse sort @$resources;
		return \@ordered;
	}
	
	return $resources;
}


# (Re)initializes the progress running, resets the indicators.
sub start_progress($) {
	my $total = shift @_;
	
	print_progress(0, $total);
	
	$last_printed_at = time();
	$loop_started_at = time();
}

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
# Prints given i out of total as a percentage 
# or only i if total is none
sub print_progress($$) {
	my ($i, $total) = @_;
	
	if ($total) {
		my $percent = ($i * 100.0) / $total;
		
		my $now = time();
		my $time_spent = $loop_started_at;
		if ($percent > 0) {
			my $remaining_seconds = int(($now - $time_spent) * (100.0 - $percent) / $percent);
			my $remaining_minutes = int($remaining_seconds / 60);
			my $minutes = int($remaining_minutes % 60);
			printf (STDERR "\t%4.2g%%, remaining approx. %d minutes \r", $percent, $minutes);
		} else {
			printf (STDERR "\t%4.2g%% \r", $percent);
		}
	} else {
		printf (STDERR "\t%d \r", $i); 
	}
}

########################################################################
# THE REST

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
