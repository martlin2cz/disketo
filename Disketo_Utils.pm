#!/usr/bin/perl
use strict;

package Disketo_Utils; 
my $VERSION=3.00.0;

# The version to be printed by --version.
use constant VERSION => "3.00.0";

# How offten (in seconds) tu orint the current orogress?
use constant PROGRESS_PERIOD => 60;

use DateTime;
use Data::Dumper;


#############################################################

sub check_args($$$$$$$) {
	my ($ARGV, $program_command, $program_name, 
		$program_description, $parameters_explanation,
		$required_args_count, $required_min_args_count) = @_;
	
	check_help($ARGV, $program_command, $program_name, $program_description, $parameters_explanation);
	check_version($ARGV, $program_name);
	check_actual_args($ARGV, $program_command, $parameters_explanation, $required_args_count, $required_min_args_count);
}

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
my $loop_started_at = 0;

#############################################################
# Iterates over the context's dirs, applying given function;
# each PROGRESS_PERIOD seconds prints percentage of done.
sub iterate_dirs($$) {
	my ($context, $function_ref) = @_;
	my @dirs = keys %{ $context->{"resources"} };

	my $total = scalar @dirs;
	start_progress($total);
	
	for (my $i = 0; $i < $total; $i++) {
		my $dir = $dirs[$i];

		$function_ref->($dir, $i);
		
		check_progress($i, $total);
	}
}

#############################################################
# Iterates over the context's files, applying given function;
# each PROGRESS_PERIOD seconds prints percentage of done.
sub iterate_files($$) {
	my ($context, $function_ref) = @_;
	my %resources = %{ $context->{"resources"} };
	my @dirs = keys %resources;
	
	my $total = scalar @dirs;
	start_progress($total);
	
	for (my $i = 0; $i < $total; $i++) {
		my $dir = $dirs[$i];
		my @files = @{ %resources{$dir} };
		my $files_count = scalar @files;
		
		for (my $j = 0; $j < $files_count; $j++) {
			my $file = $files[$j];
			$function_ref->($dir, $i, $file, $j);
		}
		
		check_progress($i, $total);
	}
}


#############################################################
# (Re)initializes the progress running, resets the indicators.
sub start_progress($) {
	my $total = shift @_;
	
	print_progress(0, $total);
	
	$last_printed_at = time();
	$loop_started_at = time();
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
		
		my $now = time();
		my $time_spent = $loop_started_at;
		if ($percent > 0) {
			my $remaining_seconds = int(($now - $time_spent) * (100.0 - $percent) / $percent);
			my $remaining_minutes = int($remaining_seconds / 60);
			my $minutes = int($remaining_minutes % 60);
			my $hours = int($remaining_minutes / 60);
			printf (STDERR "\t%4.2g%%, remaining approx. %d hours and %d minutes \r", $percent, $hours, $minutes);
		} else {
			printf (STDERR "\t%4.2g%% \r", $percent);
		}
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
