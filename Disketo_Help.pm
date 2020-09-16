#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

package Disketo_Help;
my $VERSION=3.00.0;

use Data::Dumper;
use Disketo_Utils;
use Disketo_Extras;
use Disketo_Instruction_Set;
use List::MoreUtils qw{ firstidx };

########################################################################
# Implements the functions related to help, usage, list all commands
# and context, and all that related stuff.
########################################################################


########################################################################
# TREE USAGE

# Prints the tree usage
sub print_tree_usage() {
	my $commands = Disketo_Instruction_Set::commands();
	
	my $usage = tree_usage($commands);
	
	print($usage);
}

# Computes the tree usage for the given commands
sub tree_usage($) {
	my ($commands) = @_;
	
	my $usage = "";
	for my $command (values %$commands) {
		my $command_usage = tree_subtree_usage($command, 0);
		$usage .= $command_usage;
	}
	
	return $usage;
}

# Computes the tree usage for the given command node
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

# Prints the "linear usage" (all the valid statements)
sub print_linear_usage() {
	my $commands = Disketo_Instruction_Set::commands();

	my $usage = linear_usage($commands);
	
	print(join("\n", @$usage) . "\n");
}

# Computes the "linear usage"
sub linear_usage($) {
	my ($commands) = @_;

	return valid_arg_value_usage($commands);
}

# Computes the linear usage for the "valid arg value" field 
# (a value of $command->{"valid-args"} )
sub valid_arg_value_usage($) {
	my ($valid_arg_value) = @_;
	
	if (ref($valid_arg_value) eq "HASH") {
		# if the valid arg value is operations ...
		
		my %commands = %$valid_arg_value;
		
		my @result = ();
		
		for my $command (values %commands) {
			# for each of the valid "child command"
			# compute its possible arguments usage
			my $sub_usage = linear_subtree_usage($command);

			push (@result, @$sub_usage);
		} 

		return \@result;
	} else {
		# else it's just an atomic value
		my $value_name = $valid_arg_value;
		return [ $value_name ];
	}
}

# Computes the linear usage for the given command node
sub linear_subtree_usage($) {
	my ($command) = @_;
	
	my $command_name = $command->{"name"};
	
	my @params_names = @{ $command->{"params"} };
	if (scalar (@params_names) == 0) {
		# if has no params at all,
		# the usage of that command is just its name
		return [ $command_name ];
	}
	
	# compute the usages of all its params and combine them each by each
	my @params_usages = map { param_usages($command, $_) } @params_names;
	my $combinations = combine(\@params_usages);
	my @with_command_name = map { "$command_name $_" } @$combinations;
	
	return \@with_command_name;
}

# Computes the usages array for the given param of the given command
sub param_usages($$) {
	my ($command, $param_name) = @_;
	
	my $child = $command->{"valid-args"}->{$param_name};
	my $child_usages = valid_arg_value_usage($child);

	return $child_usages;
}

# Combines the arrays of the given arrays by concatenation
# i.e. [[X,Y], [0,1]] => [X0, X1, Y0, Y1]
sub combine($) {
	my ($sets) = @_;
	
	my @sets = @$sets;
	my $first_set = shift @sets;
	if ((scalar @sets) == 0) {
		return $first_set;
	}
	
	my @result = ();
	for my $item (@$first_set) {

		my $sub_result = combine(\@sets);
		my @sub_result_with_item = map { "$item $_" } @$sub_result;
		
		push (@result, @sub_result_with_item);
	}
	return \@result;
}

########################################################################
# VALUE NODE specification

sub compute_arguments_description($) {
	my ($program) = @_;
	
	my $nodes_with_marker = Disketo_Preparer::collect_nodes_with_value($program, '$$');
	
	my $result = "";
	for my $node (@$nodes_with_marker) {
		my $node_spec = value_node_specification($program, $node);
		$result .= "  $node_spec\n";
	}
	return $result;
}

sub value_node_specification($$) {
	my ($program, $value_node) = @_;
		
	my $parent = Disketo_Analyser::parent($program, $value_node);

	my $value_name = $value_node->{"name"};
	my $command_name = $parent->{"name"};

	my @params = @{ $parent->{"operation"}->{"params"} };
	my $param_index = firstidx { $_ eq $value_node } @params;
	my $param_name = $params[$param_index];

	return "$value_name for the '$param_name' parameter of the '$command_name' command";
}

########################################################################
