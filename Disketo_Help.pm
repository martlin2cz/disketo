#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

package Disketo_Help;
my $VERSION=3.00.0;

use Data::Dumper;
use Disketo_Utils;
use Disketo_Extras;
use Disketo_Instruction_Set;


########################################################################
# Implements the functions related to help, usage, list all commands
# and context, and all that related stuff.
########################################################################


########################################################################
# TREE USAGE

sub tree_usage() {
	my $commands = Disketo_Instruction_Set::commands();
	
	my $usage = "";
	for my $command (values %$commands) {
		my $command_usage = tree_subtree_usage($command, 0);
		$usage .= $command_usage;
	}
	
	return $usage;
}

sub tree_subtree_usage($$) {
	my ($command, $padding) = @_;
	my @params = @{ $command->{"params"} };
	my %args = %{ $command->{"valid-args"} };
	my $padded = ("  " x (3 * $padding));
	
	my $command_name = $command->{"name"};
	my $doc = $command->{"doc"};
	my $params_list = join(" ", @params);
	
	my $params_spec = "";
	for my $param_name (@params) {
		my $param_value = $args{$param_name};

		$params_spec .= "$padded    $param_name:";
		if (ref($param_value) eq "HASH") {
			my %param_possiblities = %{ $param_value };
			for my $possibility (values %param_possiblities) {
				my $possibility_spec = tree_subtree_usage($possibility, $padding + 1);
				$params_spec .= "\n$possibility_spec";
			}
		} elsif ($param_value eq undef) {
			$params_spec .= " (value)\n";
		} else {
			$params_spec .= " $param_value\n";
		}
	}
	
	if ($params_spec eq "") {
		return "$padded$command_name  $params_list\n$padded  $doc\n";
	} else {
		return "$padded$command_name  $params_list\n$padded  $doc\n$padded  WHERE:\n$params_spec";
	}
}


########################################################################
# LINEAR USAGE


sub linear_usage() {
	my $commands = Disketo_Instruction_Set::commands();

	#~ my @usage = [];
	#~ for my $command (values %$commands) {
		
		#~ my $command_usages = valid_arg_value_usage($command);
		#~ push (@usage, @$command_usages);
	#~ }
	
	#~ return \@usage;
	return valid_arg_value_usage($commands);
}
sub valid_arg_value_usage($) {
	my ($valid_arg_value) = @_;
	
	if (ref($valid_arg_value) eq "HASH") {
		my %commands = %$valid_arg_value;
		
		my @result = ();
		
		for my $command_name (keys %commands) {
			#print("-> $command_name\n");
			#push @result, "[$command_name]";
			
			my $command = %commands{$command_name};
			my $child_usage = linear_subtree_usage($command);
			my @sub_usage = map { "$command_name $_" } @$child_usage;
#print(Dumper($command_name, $child_usage, \@sub_usage));
			push (@result, @sub_usage);
		} 

		return \@result;
	} else {
		my $value_name = $valid_arg_value;
		return [ $value_name ];
	}
	
}

sub linear_subtree_usage($) {
	my ($command) = @_;
	
	my @params_names = @{ $command->{"params"} };
	if (scalar (@params_names) == 0) { 
		return [ "" ];
	}
	
	my @params_usages = map { param_usages($command, $_) } @params_names;
	my $combinations = combine(\@params_usages);
	#print(Dumper(\@params_usages, \));
	return $combinations;
}

sub param_usages($$) {
	my ($command, $param_name) = @_;
	
	my $name = $command->{"name"};
	my $child = $command->{"valid-args"}->{$param_name};
	
	my $child_usages = valid_arg_value_usage($child);
#print(Dumper($name, $child_usages));
	return $child_usages;
}

sub combine($) {
	my ($params_usages) = @_;
	
	my @result = ();
	# TODO generalise!
	for my $param1 (@{ $params_usages->[0] }) {
			if ((scalar @$params_usages) > 1) {
				for my $param2 (@{ $params_usages->[1]}) {
					push @result, "$param1 $param2";
				}
			} else {
				push @result, $param1;
			}
	}
	return \@result;
}


########################################################################
