#!/usr/bin/perl
use strict;

package Disketo_Engine; 
my $VERSION=2.0.0;

use Disketo_Utils; 
use Disketo_Core;
use Data::Dumper;
use File::Basename;
########################################################################
# The core, engine, base functions for the particular operations over
# the resources. Specifies the abstract functions, with all the
# technicalities (logging, progress, ...).
########################################################################

########################################################################
# Creates the empty context.
sub create_context() {
	return { "resources" => {} };
}

########################################################################
# Performs the load resources of the given folders/from the given files
# into the given context.
sub load($$) {
	my ($roots, $context) = @_;
	my %resources = ();
	foreach my $root (@$roots) {
		#print("-> $root\n");
		my %sub_resources = %{ load_resources_from($root) };
		%resources = (%resources, %sub_resources);
	}
	
	$context->{"resources"} = \%resources;
	return \%resources;
}

########################################################################
# Performs the calculation of the given function($dir,$context) 
# to obtain given identifier over the dirs in the given context.
sub calculate_for_each_dir($$$) {
	my ($function, $identifier, $context) = @_;

	my %values = ();
	Disketo_Utils::iterate_dirs($context, sub($$) {
		my ($dir, $i) = @_;
		my $value = $function->($dir, $context);
		# TODO add only if value is not none?
		$values{$dir} = $value;
	});
	
	$context->{$identifier} = \%values;
	return \%values;
}

########################################################################
# Performs the calculation of the given function($file,$context) 
# to obtain given identifier over the files in the given context.
sub calculate_for_each_file($$$) {
	my ($function, $identifier, $context) = @_;

	my %values = ();
	Disketo_Utils::iterate_files($context, sub($$$$) {
		my ($dir, $i, $file, $j) = @_;
		my $value = $function->($file, $context);
		# TODO add only if value is not none?
		$values{$file} = $value;
	});
	
	$context->{$identifier} = \%values;
	return \%values;
}

########################################################################
# Performs the aggregation by the given groupper($dir,$context) 
# to obtain groups for the dirs in the given context.
sub group_dirs($$$) {
	my ($groupper, $identifier, $context) = @_;

	my %values = ();
	Disketo_Utils::iterate_dirs($context, sub($$) {
		my ($dir, $i) = @_;
		my $group = $groupper->($dir, $context);
		push @{$values{$group}}, $dir;
	});
	
	$context->{$identifier} = \%values;
	return \%values;
}

########################################################################
# Performs the aggregation by the given groupper($file,$context) 
# to obtain groups for the files in the given context.
sub group_files($$$) {
	my ($groupper, $identifier, $context) = @_;

	my %values = ();
	Disketo_Utils::iterate_files($context, sub($$$$) {
		my ($dir, $i, $file, $j) = @_;
		
		my $group = $groupper->($file, $context);
		push @{$values{$group}}, $file;
	});
	
	$context->{$identifier} = \%values;
	return \%values;
}


########################################################################
# Performs the filtration based on the predicate($dir,$context) 
sub filter_dirs($$) {
	my ($predicate, $context) = @_;
	my %resources = %{ $context->{"resources"} };
	
	my %new_resources = ();
	Disketo_Utils::iterate_dirs($context, sub($$) {
		my ($dir, $i) = @_;
		my $matches = $predicate->($dir, $context);
		if ($matches) {
			my $children = $resources{$dir};
			$new_resources{$dir} = $children;
		}
	});
	
	$context->{"resources"} = \%new_resources;
	return \%new_resources;
}

########################################################################
# Performs the filtration based on the predicate($file,$context) 
sub filter_files($$) {
	my ($predicate, $context) = @_;

	my %new_resources = ();
	Disketo_Utils::iterate_files($context, sub($$$$) {
		my ($dir, $i, $file, $j) = @_;
		my $matches = $predicate->($file, $context);
		if ($matches) {
			push @{ $new_resources{$dir} }, $file;
		}
	});
	
	$context->{"resources"} = \%new_resources;
	return \%new_resources;
}

########################################################################
# Performs the print based on the printer($dir,$context) 
sub print_dirs($$) {
	my ($printer, $context) = @_;

	Disketo_Utils::iterate_dirs($context, sub($$) {
		my ($dir, $i) = @_;
		my $str = $printer->($dir, $context);
		print("$str\n");
	});
}

########################################################################
# Performs the print based on the printer($file,$context) 
sub print_files($$) {
	my ($printer, $context) = @_;

	Disketo_Utils::iterate_files($context, sub($$$$) {
		my ($dir, $i, $file, $j) = @_;
		my $str = $printer->($file, $context);
		print("$str\n");
	});
}


########################################################################
# Prints the statistics about the context.
sub context_stats($) {
	my ($context) = @_;
	
	print(Dumper($context)); # XXX
	
	for my $name (keys %$context) {
		my $value = $context->{$name};
		
		#print($name . " isda " . ref($value) . "\n");
		my $desc = "ok";
		if (ref($value) eq "HASH") {
			$desc = scalar %{ $value };
		} elsif (ref($value) eq "ARRAY") {
			$desc = scalar @{ $value };
		}
		
		print("\t $name: $desc \n");
	}
}

########################################################################

sub load_resources_from($) {
	# TODO copy the core functions here?
	return Disketo_Core::list(shift @_);
}
