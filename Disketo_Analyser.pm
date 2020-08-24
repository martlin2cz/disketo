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

# Computes the instructions for the given script
sub compute_instructions($$) {
	my ($script, $commands) = @_;
	my @instructions = ();

	for my $statement (@{ $script }) {
		my $instruction = compute_instruction($statement, $commands);
		push @instructions, $instruction;
	}

	return \@instructions;
}

# Computes the instruction for the given statement.
sub compute_instruction($$) {
	my ($statement, $commands) = @_;
	
	my $tree = build_syntax_tree($statement, $commands);
	
	return $tree;
}

########################################################################

sub build_syntax_tree($$) {
	my ($statement, $commands) = @_;
	
	my $stack = [];
	return build_syntax_subree($statement, $stack, $commands);
	#TODO if stack not empty ...
}

sub build_syntax_subree($$$) {
	my ($statement, $stack, $context_commands) = @_;
#print(Dumper($statement));
	my $operation_name = shift @{ $statement };
	my $operation = $context_commands->{$operation_name};
	if (!$operation) {
#print(Dumper($context_commands));
		die("Operation " . $operation_name . " not allowed in this context. "
		. "Allowed: " . ( join(", ", (keys %{ $context_commands }))));
	}
	
	my %params = %{ $operation->{"params"} };
	my @children = ();
	for my $param (keys %params) {
		my $param_context = $params{$param};

		if ($param_context) {
			my $param_subtree = build_syntax_subree($statement, $stack, $param_context);
			push @children, $param_subtree;
		} else {
			my $param_node = build_syntax_leaf_node($statement, $stack);
			push @children, $param_node;
		}
	}
	
	return {"operation" => $operation, "arguments" => \@children };
}

sub build_syntax_leaf_node($$) {
	my ($statement, $stack) = @_;
	
	my $operation = undef; #TODO ?!

	my $value = shift @{ $statement };
	my @children = [ $value ];
	
	return {"operation" => $operation, "arguments" => \@children };
}


#~ # Extracts the command name and arguments from the given statement
#~ sub extract($) {
	#~ my ($statement) = @_;
	
	#~ my @statement = @{ $statement };
	#~ my $command_name = shift @statement;
	
	#~ return ($command_name, \@statement);
#~ }


#~ # Validates given command name (checks its existence agains given commands table)
#~ sub validate_command_name($$) {
	#~ my ($command_name, $commands) = @_;
	
	#~ my $command = %{ $commands }{$command_name};
	#~ if (!$command) {
		#~ die("Unknown command \"$command_name\"");
	#~ }

	#~ return $command;
#~ }

#~ # Validates given command params (checks the number of them)
#~ sub validate_command_params($$) {
	#~ my ($arguments, $command) = @_;
	#~ my @params = @{ $command->{"params"} };
	#~ my @arguments = @{ $arguments };

	#~ if ((scalar @params) ne (scalar @arguments)) {
		#~ my $command_name = $command->{"name"};
		#~ die("$command_name expects " . (scalar @params) . " params (" . join(", ", @params) . "), "
				#~ . "given " . (scalar @arguments) . " (". join(", ", @arguments) . ")");
	#~ }

	#~ return \@params;
#~ }

sub print_syntax_tree($) {
	my ($tree) = @_;
	print_syntax_subree($tree, 0);
}

sub print_syntax_subree($$) {
	my ($sub_tree, $padding) = @_;
	
	my $operation = $sub_tree->{"operation"};
	my @arguments = @{ $sub_tree->{"arguments"} };
	
	my $name;
	my @parameters;
	if ($operation) {
		$name = $operation->{"name"};
		@parameters = keys %{ $operation->{"params"} };
	}
	
	print(" " x $padding);
	print($name);
	print("\n");
	
	my @arguments = @{ $sub_tree->{"arguments"} };
	
	#print(Dumper(\@arguments));
	for my $i (0..(scalar @arguments - 1)) {
		my $param = $parameters[$i] or "PARAM";
		my $arg = $arguments[$i] or "ARG";
		
		print(" " x ($padding + 1));
		print($param . ":");
		print("\n");
		
		if (ref($arg) eq "HASH") {
			print_syntax_subree($arg, $padding + 2);
			
		} elsif (ref($arg) eq "ARRAY") {
			for my $argi (@{ $arg}) {
				print(" " x ($padding + 1));
				print($argi . "\n");
			}
			
		} else {
			print(" " x ($padding + 1));
			print($arg . "\n");
		}
	}
}

########################################################################

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
	my %params = %{ $command->{"params"} };
	my $padded = ("  " x (3 * $padding));
	
	my $name = $command->{"name"};
	my $doc = $command->{"doc"};
	my $params_list = join(" ", keys %params);
	
	my $params_spec = "";
	for my $param_name (keys %params) {
		my $param_value = $params{$param_name};

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
			$params_spec .= " ($param_value)\n";
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

