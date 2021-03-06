#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

package Disketo_Help;
my $VERSION=3.00.0;

use Data::Dumper;
use Disketo_Utils;
use Disketo_Instruction_Set;
use List::MoreUtils qw{ firstidx };
use Set::Scalar;

########################################################################
# Implements the functions related to help, usage, list all commands
# and context, and all that related stuff.
########################################################################
# INSTRUCTION TO LINE

# Converts the given program (back) to the string in lines.
sub program_to_linear_string($) {
	my ($program) = @_;
	
	my $result = "";
	for my $instruction (@$program) {
		$result .= instruction_to_linear_string($instruction);
		$result .= "\n";
	}
	
	return $result;
}

# Converts the given (parsed) instruction back to its original line(ar form)
sub instruction_to_linear_string($) {
	my ($instruction) = @_;
	
	my $result = "";
	
	Disketo_Analyser::walk_tree($instruction, "",
		sub { 
			my ($node, $stack, $param_name, $name, $operation, $params, $arguments) = @_;
			my $command_name = $operation->{"name"};
				$result .= "$command_name ";
		},
		sub { 
			my ($node, $stack, $param_name, $name, $value, $prepared_value) = @_; 
			$result .= "$value ";
		});
	
	return $result;
}

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

		$params_spec .= "$padded    $param_name";
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
	my $requires = $command->{"requires"};
	my $produces = $command->{"produces"};
	my $requires_spec = (scalar @$requires > 0 ? join(",", @$requires) : "none");
	my $produces_spec = (scalar @$produces > 0 ? join(",", @$produces) : "none");
	my $req_prod_spec = "requires: $requires_spec; produces: $produces_spec";
	
	if ($params_spec eq "") {
		return "$padded$command_name  $params_list\n$padded  $doc\n$padded  $req_prod_spec\n";
	} else {
		return "$padded$command_name  $params_list\n$padded  $doc\n$padded  $req_prod_spec\n$padded  WHERE:\n$params_spec";
	}
}


########################################################################
# LINEAR USAGE (ALL VALID STATEMENTS)

# Computes all the possible statements constructable.
sub compute_all_statements() {
	my $commands = Disketo_Instruction_Set::commands();
	return compute_all_statements_for($commands);
}

# Computes the linear usage for the "valid arg value" field 
# (a value of $command->{"valid-args"} )
sub compute_all_statements_for($) {
	my ($valid_arg_value) = @_;
	
	if (ref($valid_arg_value) eq "HASH") {
		# if the valid arg value is operations ...
		
		my %commands = %$valid_arg_value;
		my @result = ();
		
		for my $command (values %commands) {
			# for each of the valid "child command"
			# compute its possible arguments usage
			my $sub_usage = valid_statements_for_command($command);
			push (@result, @$sub_usage);
		} 

		return \@result;
	} else {
		# else it's just an atomic value
		my $value_spec = $valid_arg_value;
		return valid_statements_for_value($value_spec);
	}
}

# Computes the linear usage (the valid instructions nodes) 
# for the given value spec (i.e. "(the function)").
# In fact returns just list with exactly one node.
sub valid_statements_for_value($) {
	my ($value_spec) = @_;
	
	my $value_name = $value_spec;
	my $value = $value_spec;
	my $node = Disketo_Analyser::create_value_node($value_name, $value);

	return [ $node ];
}

# Computes the linear usage (the valid instructions nodes) 
# for the given command node.
# In fact returns just list of instructions nodes with all the possible
# combinations of its params.
sub valid_statements_for_command($) {
	my ($command) = @_;
	
	my $command_name = $command->{"name"};
	my @params_names = @{ $command->{"params"} };

	if (scalar (@params_names) == 0) {
		# if has no params at all,
		# the usage of that command is just the command with no children
		my $op = Disketo_Analyser::create_operation_node($command, []);
		return [ $op ];
				
	} else {
		# compute the usages of all its params and combine them each by each
		my @params_usages = map { possible_statements_of_command_param($command, $_) } @params_names;
		my $combinations = combine(\@params_usages);
		my @with_command = map { Disketo_Analyser::create_operation_node($command, $_) } @$combinations;

		return \@with_command;
	}
}

# Computes the usages array for the given param of the given command.
sub possible_statements_of_command_param($$) {
	my ($command, $param_name) = @_;
	
	my $child = $command->{"valid-args"}->{$param_name};
	my $child_usages = compute_all_statements_for($child);
	
	return $child_usages;
}

# Combines the arrays of the given arrays by creating couples
# i.e. [[X,Y], [0,1]] => [[X0], [X1], [Y0], [Y1]]
# TODO move to Utils module
sub combine($) {
	my ($sets) = @_;
	
	my @sets = @$sets;
	my $first_set = shift @sets;
	if ((scalar @sets) == 0) {
		# If we have nothing to combine with, 
		# make one combination for each item and return
		
		my @wrapped = map { [$_] } @$first_set;
		return \@wrapped;
	}
	
	my @result = ();
	for my $item (@$first_set) {
		# Otherwise iterate over each item
		# and for each item compute its sub-combinations and
		# join the item with the sub-combinations and collect
		
		my $sub_result = combine(\@sets);
		my @sub_result_with_item = map { [ ($item, @$_) ] } @$sub_result;
		push (@result, @sub_result_with_item);
	}
	return \@result;
}

########################################################################
# VALUE NODE specification

# Computes the usage description of all the nodes with the '$$' marker 
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

# Computes the usage description/specification of the given value node 
# of the given program. Names its value name, name of the parent 
# operation and the param name.
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
# LIST COMMANDS

sub print_list_of_commands_in_markdown() {
	my $commands = Disketo_Instruction_Set::commands();
	my $nodes = collect_all_commands_nodes($commands, \&print_command_node_in_markdown);
	
	print_commands_nodes($nodes, \&print_command_node_in_markdown);
}

sub collect_all_commands_nodes($$) {
	my ($commands, $node_printer) = @_;
	
	my $result = Set::Scalar->new();
	collect_command_sub_nodes($commands, $result);
	
	my @result_list = $result->elements;
	my @sorted = sort { $a->{"ID"} cmp $b->{"ID"} } @result_list;
	return \@sorted;
}

sub collect_command_sub_nodes($$) {
	my ($valid_args, $result) = @_;
	
	for my $command (values %$valid_args) {
		$result->insert($command);
		
		my $child_params_valids = $command->{"valid-args"};
		for my $child_param_valids (values %$child_params_valids) {
			if (ref($child_param_valids) eq "HASH") {
				collect_command_sub_nodes($child_param_valids, $result);
			}
		}
	}
}

# Call with:
# sub ($$$$$$$) {
# my ($id, $name, $produces, $requires, $doc, $params, $valid_args) = @_;
# (...)
# }
sub print_commands_nodes($$) {
	my ($nodes, $printer) = @_;
#print(Dumper($nodes));
	for my $node (@$nodes) {
		my $id = $node->{"ID"};
		my $name = $node->{"name"};
		my $produces = $node->{"produces"};
		my $requires = $node->{"requires"};
		my $doc = $node->{"doc"};
		my $params = $node->{"params"};
		my $valid_args = $node->{"valid-args"};
		
		my $print = $printer->($id, $name, $produces, $requires, $doc, $params, $valid_args);
		print($print);
	}
}

sub print_command_node_in_markdown($$$$$$$) {
	my ($id, $name, $produces, $requires, $doc, $params, $valid_args) = @_;

	my $rslt = "";
	my $params_spec = join(" ", @$params);
	
	$rslt .= "# $id\n";
	$rslt .= "**Usage:** `$name $params_spec`\n\n";
	$rslt .= "$doc\n\n";
	$rslt .= "\n";
	
	$rslt .= "| Parameter | Possible value(s) |\n";
	$rslt .= "| --------- | ----------------- |\n";
	if (scalar (@$params) == 0) {
		$rslt .= "| _no params_ | _no_value(s)_ |\n";
	}
	
	for my $param_name (@$params) {
		my $param_valid_args = $valid_args->{$param_name};
		my $valid_args_spec;
		
		if (ref($param_valid_args) eq "HASH") {
			$valid_args_spec = "";
			
			for my $child_operation (values %$param_valid_args) {
				my $child_operation_id = $child_operation->{"ID"};
				my $child_operation_name = $child_operation->{"name"};
				
				$valid_args_spec .= " [$child_operation_name](#$child_operation_id) ";
			}
		} else {
			$valid_args_spec = $param_valid_args;
		}
		$rslt .= "| $param_name | $valid_args_spec |\n"
	}
	$rslt .= "\n";
	
	my $requires_spec = (scalar (@$requires) > 0) ? join(" ", @$requires) : "_nothing_";
	my $produces_spec = (scalar (@$produces) > 0) ? join(" ", @$produces) : "_nothing_";
	
	$rslt .= "**Requires:** $requires_spec \n";
	$rslt .= "**Produces:** $produces_spec \n";
	$rslt .= "\n\n";

	return $rslt;
}

########################################################################

