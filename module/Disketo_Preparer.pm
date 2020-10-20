#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

package Disketo_Preparer;
my $VERSION=3.1.0;

use Data::Dumper;
use Disketo_Utils;
use Disketo_Instruction_Set;
use Disketo_Analyser;

########################################################################
# The module laying between the Analyser and Interpreter.
# Enhances the syntax forrest with some additonal semantic informations,
# and prepares to be actually executed.
########################################################################

########################################################################
# PREPARE

# Prepares the given program to be executed with the given arguments.
sub prepare_to_execute($$) {
	my ($program, $arguments) = @_;

	resolve_dependencies($program);
	
	prepare_values($program);

	my $remaining_arguments = resolve_values($program, $arguments);
	
	return $remaining_arguments;
}

# Prepares the given program to be just printed.
sub prepare_to_print($) {
	my ($program) = @_;

	resolve_dependencies($program);
	
	prepare_values($program);
}

########################################################################
# RESOLVE VALUES

# Prepares the values (strips, evaluates, converts and so).
# Adds 'prepared_value' to each value node in the given program forrest.
sub prepare_values($) {
	my ($program) = @_;

	Disketo_Analyser::walk_forrest($program, sub {},
		sub { 
			my ($node, $stack, $param_name, $name, $value, $prepared_value) = @_; 
		
			my $value_to_be_prepared = prepare_value($value);
			$node->{"prepared_value"} = $value_to_be_prepared;
		}
	);
}

# Prepares the given value.
sub prepare_value($) {
	my ($value) = @_;
	
	if ($value =~ /^\"(.*)\"$/) {
		# if "string in quotes", strip
		my ($group) = ($value =~ /\"([^\"]*)\"/);
		return $group;
	}
	if ($value =~ /^[0-9](.*)$/) {
		# if just number, keep
		return $value;
	}
	if ($value eq '$$' or $value eq '$$$') {
		# if $$ or $$$ placeholder, leave empty for now
		return undef;
	}
	if ($value =~ /^sub ?\{/) {
		# if sub { ... }, eval
		my $evaluated = eval($value);

		if ($@) {
			die("Syntax error $@ in $value");
		}
		return $evaluated;
	}
	
#	# otherwise just raise internal error
#	die("Unknown value type of: $value");

	# otherwise return it as it is
	return $value;
}

########################################################################
# RESOLVE VALUES

# Resolves the '$$' values.
# Adds each first of the arguments as 'prepared_value' field to each
# value node with value '$$'. Returns the remaining (unused) arguments.
sub resolve_values($$) {
	my ($program, $arguments) = @_;

	my $nodes_with_marker = collect_nodes_with_value($program, '$$');

	if ((scalar @$nodes_with_marker) > (scalar @$arguments)) {
		my $expected_count = (scalar @$nodes_with_marker) + 1;
		my $actual_count = (scalar @$arguments);
		my $args_desc = Disketo_Help::compute_arguments_description($program);
		die("Expected at least $expected_count script arguments, "
			. "given $actual_count. "
			. "The required script arguments are:\n"
			. "$args_desc"
			. "  [ROOT DIR OR FILE 1] ... [ROOT DIR OR FILE n]");
	}
	
	my $remaining_arguments = resolve_marker_values($nodes_with_marker, $arguments);
	
	my $nodes_with_hypermarker = collect_nodes_with_value($program, '$$$');
	resolve_hypermarker_values($nodes_with_hypermarker, $remaining_arguments);
}

# Collects all the (value) nodes with the given value.
sub collect_nodes_with_value($$) {
	my ($program, $expected_value) = @_;

	my @nodes = ();
	Disketo_Analyser::walk_forrest($program, sub {},
		sub { 
			my ($node, $stack, $param_name, $name, $value, $prepared_value) = @_; 
		
			if ($value eq $expected_value) {
				push @nodes, $node;
			}
		}
	);
	
	return \@nodes;
}

# Resolves the given nodes with '$$' marker with the given arguments.
# Puts each of the value from the arguments to the nodes as a 
# 'prepared_value' field. Returns the remaining, unused arguments.
sub resolve_marker_values($$) {
	my ($nodes, $arguments) = @_;

	my @arguments = @$arguments;

	for my $node (@$nodes) {
		my $arg = shift @arguments;
		$node->{"prepared_value"} = $arg;
	}
	
	return \@arguments;
}

# Resolves the given nodes with '$$$' marker with the given arguments.
# Puts the arguments (string array) as a 'prepared_value' field to each
# of them.
sub resolve_hypermarker_values($$) {
	my ($nodes, $arguments) = @_;

	my @arguments = @$arguments;
	for my $node (@$nodes) {
		$node->{"prepared_value"} = $arguments;
	}
	
	return \@arguments;
}


########################################################################
# RESOLVE DEPENDECIES

# Computes the metas required by the given instruction.
sub compute_requireds($) {
	my ($instruction) = @_;

	my @produceds = ();
	Disketo_Analyser::walk_tree($instruction, undef,
		sub { 
			my ($node, $stack, $param_name, $name, $operation, $params, $arguments) = @_;
			
			my $produces = $operation->{"requires"};
			push @produceds, (@$produces);
		},
		sub { 
			my ($node, $stack, $param_name, $name, $value, $prepared_value) = @_;

			if ($name eq $Disketo_Instruction_Set::META_NAME_VALNAME_REQ
			 or $name eq $Disketo_Instruction_Set::GROUP_META_NAME_VALNAME_REQ) {
				push @produceds, $prepared_value;
			}
		}
	);

	return \@produceds;
}

# Computes the metas produced by this instruction.
sub compute_produceds($) {
	my ($instruction) = @_;

	my @produceds = ();
	Disketo_Analyser::walk_tree($instruction, undef,
		sub { 
			my ($node, $stack, $param_name, $name, $operation, $params, $arguments) = @_;
			
			my $produces = $operation->{"produces"};
			push @produceds, (@$produces);
		},
		sub { 
			my ($node, $stack, $param_name, $name, $value, $prepared_value) = @_;
			
			if ($name eq $Disketo_Instruction_Set::META_NAME_VALNAME_PROD
			 or $name eq $Disketo_Instruction_Set::GROUP_META_NAME_VALNAME_PROD) {
				push @produceds, $prepared_value;
			}
		}
	);
	
	return \@produceds;
}

# Returns true if the given instruction produces the given meta.
sub produces($$) {
	my ($instruction, $meta_name) = @_;
	my $produced = compute_produceds($instruction);
	my %produceds = map { $_ => 1 } @$produced;
	return %produceds{$meta_name};
}

# Returns true if any instruction up to given index produces the specified meta.
sub is_produced_by($$$) {
	my ($program, $meta_name, $up_to_instruction_index) = @_;
	
	my $i;
	for ($i = $up_to_instruction_index; $i >= 0; $i--) {
			my $instruction = $program->[$i];
			
			if (produces($instruction, $meta_name)) {
				return 1;
			}
	}
	
	return 0;
}

# Resolves the dependeincies (fills the instructions producing the missing metas).
sub resolve_dependencies($) {
	my ($program) = @_;
	
	my $all_resolved;
	
	do {
		$all_resolved = do_one_step_of_dependency_resolution($program);
	} while (not $all_resolved);
}

# Once walks throught the program and checks whether has all its depencencies resolved.
# If not, adds the instruction producing that missing meta and returns 0.
# Otherwise (all dependencies resolved), return 1;
sub do_one_step_of_dependency_resolution($) {
	my ($program) = @_;

	my @program = @$program;
	while (my ($index, $instruction) = each @program) {
		my $requireds = compute_requireds($instruction);

		for my $required_meta (@$requireds) {
			my $is = is_produced_by($program, $required_meta, $index);
			if (not $is) {
				resolve_dependency($program, $instruction, $index, $requireds, $required_meta);
				return 0;
			}
		}
	}
	
	return 1;
}

# Resolves the given depencency. Inserts instruction producing given meta
# at given position. Fails if cannot resolve.
sub resolve_dependency($$$$$) {
	my ($program, $instruction, $index, $requireds, $required_meta) = @_;

	my $producing = compute_producing($required_meta);
	
	if (scalar @$producing == 1) {
		my $producing_instruction = $producing->[0];
		check_instructions_args($producing_instruction);
		splice @$program, $index, 0, $producing_instruction;
		
	} else {
		my $message = "The statement " . ($index + 1) . ", " 
				. "requires metas '" . (join(", ", @$requireds)) . "', "
				. "but '" . $required_meta . "' is not produced "
				. "by any of its foregoing statements.\n";
				
		if (scalar @$producing == 0) {
			$message .= "Unfortunatelly, there is no particular statement producing it. "
					. "Isn't the meta user specified?";
		}
		
		if (scalar @$producing > 1) {
			my $producing_str = join("\n", map { Disketo_Help::instruction_to_linear_string($_) } @$producing);
			$message .= "Unfortunatelly, there are more than 1 avaiable resolutions. "
					. "Plase specify the one you need manually. They are:\n$producing_str\n";
		}
		
		die($message);
	}
}

# Computes (all of them) instructions producing given meta.
sub compute_producing($) {
	my ($meta_name) = @_;
	my $all_statements = Disketo_Help::compute_all_statements();
				
	my @result = ();			
	for my $statement (@$all_statements) {
		if (produces($statement, $meta_name)) {
			push @result, $statement;
		}
	}
	
	return \@result;
}

# Checks the argument of the instruction. In fact, just sets the "$$$" value 
# to the load resources instruction.
sub check_instructions_args($) {
	my ($instruction) = @_;
	
	if (is_instruction($instruction, "load", "load-resources")) {
		my $values_node = $instruction->{"arguments"}->[0]->{"arguments"}->[0];
		$values_node->{"value"} = '$$$';
	}
}

# Checks whether the given instruction has its id and first child id.
sub is_instruction($$$) {
	my ($instruction, $expected_first_id, $expected_second_id) = @_;
	
	my $first_instruction = $instruction;
	my $first_operation = $first_instruction->{"operation"};
	my $first_id = $first_operation->{"ID"};
	if (not $first_id eq $expected_first_id) {
		return 0;
	}
	
	my $second_instruction = $instruction->{"arguments"}->[0];
	my $second_operation = $second_instruction->{"operation"};
	my $second_id = $second_operation->{"ID"};
	if (not $second_id eq $expected_second_id) {
		return 0;
	}
	
	return 1;
	}

########################################################################
