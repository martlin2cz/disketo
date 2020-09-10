#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

package Disketo_Preparer;
my $VERSION=3.0.0;

use Data::Dumper;
use Disketo_Utils;
use Disketo_Extras;
use Disketo_Instruction_Set;
use Disketo_Analyser;

########################################################################
# The module laying between the Analyser and Interpreter.
# Enhances the syntax forrest with some additonal semantic informations,
# and prepares to be actually executed.
#

########################################################################
# PREPARE

sub prepare_to_execute($$) {
	my ($program, $arguments) = @_;
	
	insert_load($program); #FIXMe use the fill_missing_dependencies for it
	
	prepare_values($program);

	my $remaining_arguments = resolve_values($program, $arguments);

	verify_dependencies($program); #TODO replace by fill_missing_dependencies
	
	return $remaining_arguments;
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
	
	if ($value =~ "\"(.*)\"") {
		# if "string in quotes", strip
		my ($group) = ($value =~ /"([^"]*)"/);
		return $group;
	}
	if ($value =~ "[0-9].*") {
		# if just number, keep
		return $value;
	}
	if ($value eq '$$' or $value eq '$$$') {
		# if $$ or $$$ placeholder, leave empty
		return undef;
	}
	
	if ($value =~ "sub ?\{(.*)\}") {
		# if sub { ... }, eval
		my $evaluated = eval($value);
		#TODO handle error
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
		die("Expected at least " . (scalar @$nodes_with_marker) . " script arguments, "
			. "given " . (scalar @$arguments));
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

sub insert_load($) {
	my ($program) = @_;

	my $commands = Disketo_Instruction_Set::commands();
	my $operation = $commands->{"load"};
	
	my $value = Disketo_Analyser::create_value_node('$$$', "(the roots)");
	my $children = [$value];
	my $instruction = Disketo_Analyser::create_operation_node($operation, $children);
	
	unshift @$program, $instruction;
}

#~ #DEPRECATED
#~ # Inserts instructions producing required metas
#~ sub fill_requireds($$) {
	#~ my ($program, $commands) = @_;
	
	#~ my @new_program = ();
	#~ my @produced = [];
	#~ Disketo_Analyser::walk_forrest($program, sub {
		#~ my ($instruction,$command_name,$command,$args,$resolved_args) = @_;
		
		#~ my $missings = find_missing_required_metas($command, \@produced);
		#~ for my $missing_meta_name (@{ $missings }) {
			#~ my $new_command = find_first_command_producing_meta($missing_meta_name, $commands);
			#~ if (!$new_command) {
				#~ die("Meta '" . $missing_meta_name . "' is not produced by any command\n");
			#~ }
			
			#~ my $new_instruction = Disketo_Instruction_Set::prepending_instruction($instruction, $new_command);
			#~ push @new_program, $new_instruction;
		#~ }
		
		#~ if ($command->{"produces"}) {
			#~ push @produced, $command->{"produces"};
		#~ }
		
		#~ push @new_program, $instruction;
	#~ }, sub {});
	
	#~ return \@new_program;
#~ }

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



#~ #DEPRECATED
#~ # Computes the array of metas names which are required by the given command but not yet produced
#~ sub find_missing_required_metas($$) {
	#~ my ($command, $produced) = @_;
	
	#~ my @requireds = @{ $command->{"requires"} };
	#~ my @produceds = @{ $produced };
	#~ my @missings = ();

	#~ for my $required (@requireds) {
		#~ my $found = 0;
		
		#~ for my $produced (@produceds) {
			#~ if ($required eq $produced) {
				#~ $found = 1;
			#~ }
		#~ }
		
		#~ if ($found eq 0) {
			#~ push @missings, $required;
		#~ }
	#~ }
	
	#~ return \@missings;
#~ }

#~ #DEPRECATED
#~ # Returns first command producing the given meta.
#~ sub find_first_command_producing_meta($$) {
	#~ my ($required_meta, $commands) = @_;
       
	#~ my %commands = %{ $commands };
               
	#~ for my $another_command (values %commands) {
		#~ if ($another_command->{"produces"} eq $required_meta) {
			#~ return $another_command;
		#~ }
	#~ }
	
	#~ return undef;
#~ }

########################################################################
