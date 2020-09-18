#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

package Disketo_Preparer;
my $VERSION=3.0.0;

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

	insert_load($program); #FIXME use the fill_missing_dependencies for it
	
	prepare_values($program);

	my $remaining_arguments = resolve_values($program, $arguments);

	verify_dependencies($program); #TODO replace by fill_missing_dependencies
	
	return $remaining_arguments;
}

# Prepares the given program to be just printed.
sub prepare_to_print($) {
	my ($program) = @_;

	insert_load($program); #FIXME use the fill_missing_dependencies for it
	
	prepare_values($program);

	verify_dependencies($program); #TODO replace by fill_missing_dependencies
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
# VERIFY MISSING METAS

# Inserts the load instruction at the very beggining of the given program.
# No f****s given about already existing load instruction at the 
# beggining of the program, or its unnecessarity.
sub insert_load($) {
	my ($program) = @_;

	my $commands = Disketo_Instruction_Set::commands();
	my $operation = $commands->{"load"};
	
	my $value = Disketo_Analyser::create_value_node('$$$', "(the roots)");
	my $children = [$value];
	my $instruction = Disketo_Analyser::create_operation_node($operation, $children);
	
	unshift @$program, $instruction;
}

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
		sub {}
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
		sub {}
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

# Verifies all the instructions gets its specified metas produced.
sub verify_dependencies($) {
	my ($program) = @_;
	
	while (my ($index, $instruction) = each @$program) {
		my $requireds = compute_requireds($instruction);
		
		for my $required (@$requireds) {
			my $is = is_produced_by($program, $required, $index);
			if (not $is) {
				die("The meta " 
				. "'" . $required . "' is required "
				. "by the statement " . ($index + 1) . ", "
				. "but none of its foregoing statements produces it.");
			}
		}
	}
}

########################################################################