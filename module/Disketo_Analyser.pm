#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

package Disketo_Analyser;
my $VERSION=3.0.0;

use Data::Dumper;
use Disketo_Utils;
use Disketo_Instruction_Set;

########################################################################

# Implements the syntactic and semantic analysis of the disketo script.
# Results in the disketo program. 
# Does all the static analysis, without knowledge of the particular 
# script arguments which is the script beeing called with.

########################################################################

# Runs the semantic analysis. Takes a script ref, returns program ref.
sub analyse($) {
	my ($script) = @_;
	my $commands = Disketo_Instruction_Set::commands();
	
	my $program = compute_instructions($script, $commands);
	return $program;
}

########################################################################
# PARSE (SCRIPT -> PROGRAM)

# Computes the instructions for the given script
sub compute_instructions($$) {
	my ($script, $commands) = @_;
	my @instructions = ();

	while (my ($i, $statement) = each @$script) {
		my $statement_number = $i + 1;
		my $instruction = compute_instruction($statement, $statement_number, $commands);
		push @instructions, $instruction;
	}

	return \@instructions;
}

# Computes the instruction for the given statement.
sub compute_instruction($$$) {
	my ($statement, $statement_number, $commands) = @_;
	
	my $tree = build_syntax_tree($statement, $statement_number, $commands);
	
	return $tree;
}

########################################################################
# BUILD SYNTAX TREE FOR THE STATEMENT

# Builds the syntax (sub)tree for the given statement (remainder)
# and the (in the current context allowed) commands hash.
sub build_syntax_tree($$$) {
	my ($statement, $statement_number, $commands) = @_;
	
	my $statement_spec = "statement $statement_number";
	my $stack = [$statement_spec];
	my $allowed_commands = $commands;
	
	my $tree = process_next_token($statement, $stack, $commands);
	
	if ((scalar @$statement) > 0) {
		die("Extra tokens '" . join(" ", @$statement) . "' at the end of the statement $statement_number.");
	}
	
	return $tree;
}

# Consumes first token from the statement
# and produces new syntax tree node.
sub process_next_token($$$) {
	my ($statement, $stack, $allowed_commands) = @_;
	if ((scalar @$statement) == 0) {
		print STDERR ("Missing some token(s) in: " . ( join(" -> ", @$stack)) . ".\n");
	}
	
	my $next_token = shift @{ $statement };

	my $expected_operation = ref($allowed_commands) eq "HASH";
	my $is_operation = is_operation($next_token);

	#print("Token: '$next_token', is it operation? $is_operation. Expected operation? $expected_operation.\n");
	if ($expected_operation and $is_operation) {
		# operation where expected, fine
		my $operation_name = $next_token;
		return process_as_operation($operation_name, $statement, $stack, $allowed_commands);
		
	} elsif (not $expected_operation and $is_operation) {
		# operation where just atomic value expected
		my $allowed_value = $allowed_commands;
		die("Expected value " . $allowed_value . ", found: '" . $next_token . "' "
			. "in: " . ( join(" -> ", @$stack)) . ". ");
	
	} elsif ($expected_operation and not $is_operation) {
		# value where operation expected
		my $value = $next_token;
		die("Expected operation "
			. "(some of: " . ( join(", ", (keys %{ $allowed_commands }))). "), "
			. "found: '" . $value . "' "
			. "in: " . ( join(" -> ", @$stack)) . ". ");
		
	} elsif (not $expected_operation and not $is_operation) {
		# value where value expected
		my $value = $next_token;
		my $allowed_value = $allowed_commands;
		return process_as_value($value, $allowed_value);
	}
}

# Processes the given (potentional) operation_name with the given statement
# remainer, with the given commands allowed at the current context.
# Produces new node.
sub process_as_operation($$$$) {
	my ($operation_name, $statement, $stack, $allowed_commands) = @_;

	my $operation = $allowed_commands->{$operation_name};
	if (!$operation) {
		die("Operation '" . $operation_name . "' not allowed "
			. "in: " . ( join(" -> ", @$stack)) . ". "
			. "Allowed: " . ( join(", ", (keys %{ $allowed_commands }))));
	}

	my @params = @{ $operation->{"params"} };
	my @children = ();
	for my $param (@params) {
		my $allowed_sub_commands = $operation->{"valid-args"}->{$param};
		push @$stack, $operation_name;
		
		my $child = process_next_token($statement, $stack, $allowed_sub_commands);
		push @children, $child;
	}
	
	return create_operation_node($operation, \@children);
}

# Processes the given value with the given allowed value specifier.
# Produces new node.
sub process_as_value($$) {
	my ($value, $value_spec) = @_;
	
	return create_value_node($value, $value_spec);
}

# Returns true, if the given token is operation name 
# (sequence of alfanum charaters and dashes, and not in quotes).
sub is_operation($) {
	my ($name) = @_;
	
	return ($name =~ /^([a-z][a-z0-9\-]+)$/);
}

# Creates the (leaf) node for the (given) value.
sub create_value_node($$) {
	my ($value, $value_spec) = @_;
	
	return {"name" => $value_spec, "value" => $value };
}

# Creates the (inner) node for the given operation and child nodes.
sub create_operation_node($$) {
	my ($operation, $children) = @_;

	my $name = $operation->{"name"};
	
	return {"name" => $name, "operation" => $operation, "arguments" => $children };
	#return {"name" => $name, "arguments" => $children };
}

########################################################################
# PRINTS

sub print_inner_node($$$$$) {
	my ($node, $stack, $param_name, $name, $operation, $params, $arguments) = @_;
	my $padding = "    " x ((scalar @$stack) - 1);
	
	#print("$padding [$param_name]\n");
	#print("$padding   $name:\n");
	print("$padding   [$param_name] $name:\n");
}

sub print_leaf_node($$$$$$) {
	my ($node, $stack, $param_name, $name, $value, $prepared_value) = @_;
	my $padding = "    " x ((scalar @$stack) - 1);
	
	#print("$padding [$param_name]\n");
	#print("$padding   $name: $value\n");
	print("$padding   [$param_name] $name: $value\n");
}

sub print_syntax_forrest($) {
	my ($forrest) = @_;
	walk_forrest($forrest, \&print_inner_node, \&print_leaf_node);
} 

sub print_syntax_tree($$) {
	my ($tree, $tree_number) = @_;
	walk_tree($tree, $tree_number, \&print_inner_node, \&print_leaf_node);
} 

########################################################################
# UTILITIES, WALK

# Walks the given tree with given functions annotated:
# sub { my ($node, $stack, $param_name, $name, $operation, $params, $arguments) = @_; }
# sub { my ($node, $stack, $param_name, $name, $value, $prepared_value) = @_; }
sub walk_forrest($$$) {
	my ($trees, $operation_node_fn, $value_node_fn) = @_;
	
	while (my ($i, $tree) = each @$trees) {
		my $tree_number = $i + 1;
		
		walk_tree($tree, $tree_number, $operation_node_fn, $value_node_fn);
	}
}

# Walks the given tree.
sub walk_tree($$$$) {
	my ($tree, $tree_number, $operation_node_fn, $value_node_fn) = @_;
	
	my $param_name = "Statement $tree_number";	
	my @stack = [ $param_name ];
	my $root = $tree;
	
	walk_tree_node($root, \@stack, $param_name, $operation_node_fn, $value_node_fn);
}

# Walks the given tree node.
sub walk_tree_node($$$$) {
	my ($node, $stack, $param_name, $operation_node_fn, $value_node_fn) = @_;

	my $name = $node->{"name"};
	if (exists($node->{"operation"})) {
		my $operation = $node->{"operation"};
		my $params = $operation->{"params"};
		my $arguments = $node->{"arguments"};

		$operation_node_fn->($node, $stack, $param_name, $name, $operation, $params, $arguments);
		
		my @sub_stack = @$stack;
		push @sub_stack, $name;
		
		while (my ($i, $param_name) = each @$params) {
			my $child_node = $arguments->[$i];
			walk_tree_node($child_node, \@sub_stack, $param_name, $operation_node_fn, $value_node_fn);
		}
		
	} elsif (exists($node->{"value"})) {
		my $value = $node->{"value"};
		my $prepared_value = $node->{"prepared_value"};

		$value_node_fn->($node, $stack, $param_name, $name, $value, $prepared_value);
	} else {
		#print(Dumper($node));
		die("Unknown node.");
	}
}

# In the given forrest finds the parent node of the given node.
sub parent($$) {
	my ($program, $child_node) = @_;

	my $parent = undef;
	walk_forrest($program,
		sub { 
			my ($node, $stack, $param_name, $name, $operation, $params, $arguments) = @_; 
			for my $child (@$arguments) {
				if ($child eq $child_node) {
					$parent = $node;
				}
			}
		},
		sub {});
	
	return $parent;
}
