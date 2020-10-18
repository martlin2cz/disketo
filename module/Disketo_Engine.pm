#!/usr/bin/perl
use strict;

package Disketo_Engine; 
my $VERSION=3.0.0;

use Disketo_Utils;
use Disketo_IO;
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
	#print("*** load \n");
	my ($roots, $context) = @_;
	my %resources = ();
	foreach my $root (@$roots) {
		#print("-> $root\n");
		my %sub_resources = %{ Disketo_IO::list($root) };
		%resources = (%resources, %sub_resources);
	}
	
	$context->{"resources"} = \%resources;
	return \%resources;
}

########################################################################
# Performs the calculation of the given function($dir,$context) 
# to obtain given identifier over the dirs in the given context.
sub calculate_for_each_dir($$$) {
	#print("*** calculate_for_each_dir \n");
	my ($function, $identifier, $context) = @_;

	my %values = ();
	$context->{$identifier} = \%values; #store to context to make it usable during the computation

	Disketo_Utils::iterate_dirs($context, $Disketo_Utils::ORDER_DIR_LAST, sub($$) {
		my ($dir, $i) = @_;
		my $value = $function->($dir, $context);
		$values{$dir} = $value;
	});
	
	return \%values;
}

# Performs the calculation of the given function($file,$context) 
# to obtain given identifier over the files in the given context.
sub calculate_for_each_file($$$) {
	#print("*** calculate_for_each_file \n");
	my ($function, $identifier, $context) = @_;

	my %values = ();
	$context->{$identifier} = \%values; #store to context to make it usable during the computation
	
	Disketo_Utils::iterate_files($context, $Disketo_Utils::ORDER_DIR_LAST, sub($$$$) {
		my ($dir, $i, $file, $j) = @_;
		my $value = $function->($file, $context);
		$values{$file} = $value;
	});
	
	return \%values;
}

########################################################################
# Performs the aggregation by the given groupper($dir,$context) 
# to obtain groups for the dirs in the given context.
sub group_dirs($$$) {
	#print("*** group_dirs \n");
	my ($groupper, $identifier, $context) = @_;

	my %groups = ();
	my %meta = ();
	Disketo_Utils::iterate_dirs($context, $Disketo_Utils::UNORDERED, sub($$) {
		my ($dir, $i) = @_;
		my $group_name = $groupper->($dir, $context);
		push @{$groups{$group_name}}, $dir;
		
		my $group = $groups{$group_name};
		$meta{$dir} = $group;
	});
	
	$context->{$identifier} = \%meta;
	return \%meta;
}

# Performs the aggregation by the given groupper($file,$context) 
# to obtain groups for the files in the given context.
sub group_files($$$) {
	#print("*** group_files \n");
	my ($groupper, $identifier, $context) = @_;

	my %groups = ();
	my %meta = ();
	Disketo_Utils::iterate_files($context, $Disketo_Utils::UNORDERED, sub($$$$) {
		my ($dir, $i, $file, $j) = @_;
		
		my $group_name = $groupper->($file, $context);
		push @{$groups{$group_name}}, $file;
		
		my $group = $groups{$group_name};
		$meta{$file} = $group;
	});
	
	$context->{$identifier} = \%meta;
	return \%meta;
}


########################################################################
# Performs the filtration based on the predicate($dir,$context) 
sub filter_dirs($$) {
	#print("*** filter_dirs \n");
	my ($predicate, $context) = @_;
	my %resources = %{ $context->{"resources"} };
	
	my %new_resources = ();
	Disketo_Utils::iterate_dirs($context, $Disketo_Utils::UNORDERED, sub($$) {
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

# Performs the filtration based on the predicate($file,$context) 
sub filter_files($$) {
	#print("*** filter_files \n");
	my ($predicate, $context) = @_;

	my %new_resources = ();
	Disketo_Utils::iterate_files($context, $Disketo_Utils::UNORDERED, sub($$$$) {
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
	#print("*** print_dirs \n");
	my ($printer, $context) = @_;

	Disketo_Utils::iterate_dirs($context, $Disketo_Utils::ORDER_DIR_FIRST, sub($$) {
		my ($dir, $i) = @_;
		my $str = $printer->($dir, $context);
		print("$str\n");
	});
}

# Performs the print based on the printer($file,$context) 
sub print_files($$) {
	#print("*** print_files \n");
	my ($printer, $context) = @_;

	Disketo_Utils::iterate_files($context, $Disketo_Utils::ORDER_DIR_FIRST, sub($$$$) {
		my ($dir, $i, $file, $j) = @_;
		my $str = $printer->($file, $context);
		print("$str\n");
	});
}


########################################################################
# Prints the (basic) statistics about the context.
sub context_stats($) {
	#print("*** context_stats \n");
	my ($context) = @_;
	
	my $resources = $context->{"resources"};
	my $count = scalar (keys %$resources);
	
	my $metas_names = join(", ", keys %$context);
	print STDERR ("Currently having metas/fields/groups named: $metas_names\n");
	print STDERR ("The resources contains $count directories\n");
}

# Prints the (expert) statistics about the context.
sub context_debug_stats($) {
	#print("*** context_debug_stats \n");
	my ($context) = @_;
	
	print STDERR (Dumper($context));
}

########################################################################
