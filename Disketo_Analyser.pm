#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

package Disketo_Analyser;
my $VERSION=3.0.0;

use Data::Dumper;
use Disketo_Utils;
use Disketo_Extras;
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
	$program = fill_requireds($program, $commands);
	
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
	return process_next_token($statement, $stack, $commands);
	#TODO if stack not empty ...
}

# Consumes first token from the statement
# and produces new syntax tree node.
sub process_next_token($$$) {
	my ($statement, $stack, $allowed_commands) = @_;
	
	my $next_token = shift @{ $statement };

	my $expected_operation = ref($allowed_commands) eq "HASH";
	my $is_operation = is_operation($next_token);
	
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
# FILL MISSING METAS

# Inserts instructions producing required metas
sub fill_requireds($$) {
	my ($program, $commands) = @_;
	
	my @new_program = ();
	my @produced = [];
	walk_program($program, sub {
		my ($instruction,$command_name,$command,$args,$resolved_args) = @_;
		
		my $missings = find_missing_required_metas($command, \@produced);
		for my $missing_meta_name (@{ $missings }) {
			my $new_command = find_first_command_producing_meta($missing_meta_name, $commands);
			if (!$new_command) {
				die("Meta '" . $missing_meta_name . "' is not produced by any command\n");
			}
			
			my $new_instruction = Disketo_Instruction_Set::prepending_instruction($instruction, $new_command);
			push @new_program, $new_instruction;
		}
		
		if ($command->{"produces"}) {
			push @produced, $command->{"produces"};
		}
		
		push @new_program, $instruction;
	});
	
	return \@new_program;
}

# Computes the array of metas names which are required by the given command but not yet produced
sub find_missing_required_metas($$) {
	my ($command, $produced) = @_;
	
	my @requireds = @{ $command->{"requires"} };
	my @produceds = @{ $produced };
	my @missings = ();

	for my $required (@requireds) {
		my $found = 0;
		
		for my $produced (@produceds) {
			if ($required eq $produced) {
				$found = 1;
			}
		}
		
		if ($found eq 0) {
			push @missings, $required;
		}
	}
	
	return \@missings;
}

# Returns first command producing the given meta.
sub find_first_command_producing_meta($$) {
	my ($required_meta, $commands) = @_;
       
	my %commands = %{ $commands };
               
	for my $another_command (values %commands) {
		if ($another_command->{"produces"} eq $required_meta) {
			return $another_command;
		}
	}
	
	return undef;
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
	my ($node, $stack, $param_name, $name, $value, $prepared_value, $resolved_value) = @_;
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

#~ sub print_syntax_forrest($) {
	#~ my ($trees) = @_;
	
	#~ while (my ($i, $tree) = each @$trees) {
		#~ my $tree_number = $i + 1;
		
		#~ print_syntax_tree($tree, $tree_number);
	#~ }
#~ }

#~ sub print_syntax_tree($$) {
	#~ my ($tree, $tree_number) = @_;
	
	#~ print("Statement $tree_number:\n");
	#~ print_syntax_subree($tree, 1);
#~ }

#~ sub print_syntax_subree($$) {
	#~ my ($sub_tree, $padding) = @_;
	
	#~ my $name = $sub_tree->{"name"};

	#~ print(" " x $padding);
	#~ print($name . "");
	#~ print("\n");
	
	#~ if ($sub_tree->{"operation"}) {
		#~ my $operation = $sub_tree->{"operation"};
		#~ my @parameters = @{ $operation->{"params"} };
		#~ my @arguments = @{ $sub_tree->{"arguments"} };
	
		#~ for my $i (0..(scalar @arguments - 1)) {
			#~ my $param = $parameters[$i] or "PARAM";
			#~ my $arg = $arguments[$i] or "ARG";
			
			#~ print(" " x ($padding + 1));
			#~ print("[" . $param . "]");
			#~ print("\n");
		
			#~ print_syntax_subree($arg, $padding + 4);
		#~ }
	#~ }
	#~ if ($sub_tree->{"value"}) {
		#~ my $value = $sub_tree->{"value"};
		
		#~ print(" " x ($padding + 2));
		#~ print($value);
		#~ print("\n");
	
	#~ }
#~ }



########################################################################
# UTILITIES, WALK

# Walks the given tree with given functions annotated:
# sub { my ($node, $stack, $param_name, $name, $operation, $params, $arguments) = @_; }
# sub { my ($node, $stack, $param_name, $name, $value, $prepared_value, $resolved_value) = @_; }
sub walk_forrest($$$$) {
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
	if ($node->{"operation"}) {
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
		
	} elsif ($node->{"value"}) {
		my $value = $node->{"value"};
		my $prepared_value = $node->{"prepared_value"};
		my $resolved_value = $node->{"resolved_value"};

		$value_node_fn->($node, $stack, $param_name, $name, $value, $prepared_value, $resolved_value);
	} else {
		die("Unknown node.");
	}
}

# DEPRECATED
# Utility method for simplified walking throught an program.
sub walk_program($$) {
	my ($program, $instruction_runner) = @_;

	for my $instruction (@{ $program }) {
		my $command = $instruction->{"command"};
		my $args = $instruction->{"arguments"};
		my $resolved_args = $instruction->{"resolved_args"};
		
		my $command_name = $command->{"name"};
	
		$instruction_runner->
			($instruction, $command_name, $command, $args, $resolved_args);
	}
}

########################################################################
# USAGE

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
	
	my $name = $command->{"name"};
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
		return "$padded$name  $params_list\n$padded  $doc\n";
	} else {
		return "$padded$name  $params_list\n$padded  $doc\n$padded  WHERE:\n$params_spec";
	}
}

#~ sub linear_usage() {
		#~ my $commands = Disketo_Instruction_Set::commands();
	
	
	#~ my @usage = [];
	#~ for my $command (values %$commands) {
		#~ my $name = $command->{"name"};
		#~ my $statement_base = $name;
		
		#~ my $command_usage = linear_subtree_usage($statement_base, $command);
		#~ push (@usage, @$command_usage);
	#~ }
	
	#~ return \@usage;
#~ }

#~ sub linear_subtree_usage($$) {
	#~ my ($statement_base, $command) = @_;
	#~ my @params_values = values %{ $command->{"params"} };
	
	#~ my @items = [];
	#~ for my $param_value (@params_values) {
		
		#~ if (ref($param_value) eq "HASH") {
			#~ my %param_possiblities = %{ $param_value };
			#~ for my $possibility (values %param_possiblities) {
				#~ my $possibility_name = $possibility->{"name"};
				#~ my $statement = "$statement_base $possibility_name";
				#~ #push @items, "$statement\n";
				
				#~ my $possibility_statements = linear_subtree_usage($statement, $possibility);
				#~ #push (@items, @{ $possibility_statements });
				#~ ## TODO FIXME IMPLEMENTME ...
			#~ }
		#~ } elsif ($param_value eq undef) {
			#~ my $statement = "$statement_base (value)";
				#~ #push @items, "$statement\n";
		#~ } else {
			#~ my $statement = "$statement_base ($param_value)";
				#~ #push @items, "$statement\n";
		#~ }
	#~ }
	
	#~ return \@items;
	
#~ }

