#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

package Disketo_Analyser;
my $VERSION=2.1.0;

use Data::Dumper;
use Disketo_Utils;
use Disketo_Extras;
use Disketo_Instruction_Set;

#######################################

# Runs the validation, in fuckt semantic analysis (converts "statements" into "program")
sub validate($) {
	my ($parsed_ref) = @_;

	my $commands = Disketo_Instruction_Set::commands();
	my @program = ();

	for my $statement_ref (@{ $parsed_ref }) {
		my ($statement_mod_ref, $cmdname, $command) = validate_function($statement_ref, $commands);
		
		my $resolved_args_ref = validate_params($statement_mod_ref, $cmdname, $command);

		my %instruction = ( "command" => $command, "arguments" => $resolved_args_ref );
		push @program, \%instruction;
	}

	return \@program;
}

# Validates given function (checks her existence agains given commands table)
sub validate_function($$) {
	my ($statement_ref, $commands) = @_;
	
	my @statement = @{ $statement_ref };
	my $fnname = shift @statement;

	my $function_ref = %{ $commands }{$fnname};
	if (!$function_ref) {
		die("Unknown command \"$fnname\"");
	}

	return (\@statement, $fnname, $function_ref);
}

# Validates params of given function (checks the number of them)
sub validate_params($$$) {
	my ($statement_ref, $fnname, $function_ref) = @_;
	my %function = %{ $function_ref };
	my @params = @{ $function{"params"} };
	my @arguments = @{ $statement_ref };

	if ((scalar @params) ne (scalar @arguments)) {
		die("$fnname expects " . (scalar @params) . " params (" . join(", ", @params) . "), "
				. "given " . (scalar @arguments) . " (". join(", ", @arguments) . ")");
	}

	return \@arguments;
}

#######################################

# Prints usage of the app with script specified
sub print_usage($$$) {
	my ($script_name, $program_ref, $program_args_ref) = @_;
	my @args = @{ $program_args_ref };
	
	my $usage = "$script_name ";
	my $count = 0;
	walk_program($program_ref, sub {
		my ($instruction_ref,$function_name,$function_method,$requires,$produces,$params_ref,$args_ref)	= @_;

		for (my $i = 0; $i < scalar @{ $params_ref }; $i++) {
			my $param = $params_ref->[$i];
			my $arg = $args_ref->[$i];

			if ($arg eq "\$\$") {
				$usage = $usage . "<$param of $function_name> ";
				$count++;
			}
		}
	});
	$usage = $usage . "<DIRECTORY/FILE ...>";
	
	print STDERR "Expected at least " . ($count + 1) . " arguments, given " . (scalar @{ $program_args_ref }) . "\n";
	Disketo_Utils::usage([], $usage);
}

# Goes throught given program and counts number of "$$" occurences
sub count_params($) {
	my ($program_ref) = @_;

	my $count = 0;
	walk_program($program_ref, sub {
		my ($instruction_ref,$function_name,$function_method,$requires,$produces,$params_ref,$args_ref)	= @_;

		for my $arg (@{ $args_ref }) {
			if ($arg eq "\$\$") {
				$count++;
			}
		}
	});

	return $count;
}


#######################################

# Prepares the program to print/execute (inserts load_* instructions where needed)
sub prepare($$) {
	my ($program_ref, $program_args_ref) = @_;

	$program_ref = insert_loads($program_ref);
	
	return $program_ref;
}

# Inserts required instructions where needed
sub insert_loads($) {
	my ($program_ref) = @_;
	
	my $commands = Disketo_Instruction_Set::commands();
	
	my @program_mod = ();
	
	my $load_command = $commands->{"load"};
	my $load_instruction = {"command" => $load_command, "arguments" => [] };
	push @program_mod, $load_instruction;

	walk_program($program_ref, sub {
		my ($instruction_ref,$function_name,$function_method,$requires,$produces,$params_ref,$args_ref)	= @_;
		
		for my $required_meta  (@{ $requires }) {
			if (meta_already_produced(\@program_mod, $required_meta)) {
				next;
			}
			
			my $new_command = find_first_command_producing_meta($required_meta);
			if (!$new_command) {
				die("Meta '" . $required_meta . "' is not produced by any command\n");
			}
			
			my $new_instruction = Disketo_Instruction_Set::prepending_instruction($instruction_ref, $new_command);
			push @program_mod, $new_instruction;
		}

		push @program_mod, $instruction_ref;
	});

	return \@program_mod;
}

sub meta_already_produced($$) {
	my ($program, $meta_name) = @_;
	
	
	for my $instruction (@{ $program }) {
		my $produces = $instruction->{"command"}->{"produces"};
		if ($produces eq $meta_name) {
			return 1;
		}
	}
	
	return 0;
}

sub find_first_command_producing_meta($$) {
	my ($required_meta) = @_;
	
	my %commands = %{ Disketo_Instruction_Set::commands() };
		
	for my $another_command (values %commands) {
		if ($another_command->{"produces"} eq $required_meta) {
			return $another_command;
		}
	}
	
	return undef;
}


#######################################

# Prints the program (with arguments)
sub print_program($$) {
	my ($program_ref, $program_args_ref) = @_;
	my @program_args = @{ $program_args_ref };

	my ($use_args_ref, $dirs_to_list) = extract_dirs_to_list($program_ref, $program_args_ref);	
	my @args_to_use = @{ $use_args_ref };

	walk_program($program_ref, sub {
		my ($instruction_ref,$instruction_name,$instruction_method,$requires,$produces,$params_ref,$args_ref) = @_;

		print STDERR "Will invoke $instruction_name:\n";
		if ($instruction_name eq "list_all_directories") {
			print STDERR "\t with directories " . join(", ", @{ $dirs_to_list }) . "\n";
		} else {
			my $index;

			my @params = @{ $params_ref };
			my @args = @{ $args_ref };
			for ($index = 0; $index < scalar @params; $index++) {
				my $param = $params[$index];
				my $arg = $args[$index];

				if ($arg eq "\$\$") {
					my $value = shift @args_to_use;
					print STDERR "\t$param := $arg, which is currently $value\n";
				} else {
					print STDERR "\t$param := $arg\n";
					if ($arg =~ "sub ?\{") {
						eval($arg);
						if ($@) {
							print STDERR "\tWarning, previous instruction contains syntax error: $@\n";
						}
					}
				}
			}
		}
	});
}

# Runs the given program. What else?
sub run_program($$) {
	my ($program_ref, $program_args_ref) = @_;
	
	my ($use_args_ref, $dirs_to_list) = extract_dirs_to_list($program_ref, $program_args_ref);
	my @use_args = @{ $use_args_ref };

	my $context = Disketo_Engine::create_context();
	
	walk_program($program_ref, sub {
		my ($instruction_ref,$instruction_name,$instruction_method,$requires,$produces,$params_ref,$args_ref) = @_;
		my $arguments_ref;
		($arguments_ref, $use_args_ref) = prepare_arguments($instruction_name, $context, $args_ref, $use_args_ref, $dirs_to_list);
		
		print "Will invoke $instruction_name with " . join(", ", @{ $arguments_ref }) . " ...\n";
		$instruction_method->(@{ $arguments_ref });
		print("Executed instruction " . $instruction_name . ", having " . (scalar (keys %{ $context->{"resources"} })) . " dirs\n");
	});
}

sub prepare_arguments($) {
	my ($instruction_name, $context, $args_ref, $use_args_ref, $dirs_to_list) = @_;
	my @use_args = @{ $use_args_ref };

	my @arguments = ($context);

	if ($instruction_name ne "load") {
		push @arguments, @{ $args_ref };
		@arguments = map {
			my $result = $_;
			if ($_ == $context) {
				$result = $_;
			}
			if ($_ eq "\$\$") {
				$result = shift @use_args;
			}
			if ($_ =~ "sub ?\{") {
				$result = eval($_);
				if ($@) {
					print STDERR "Syntax error $@ in $_\n";
				}
			}
			$result;
		} @arguments;
	} else {
		push @arguments, $dirs_to_list;
	}
	
	return (\@arguments, \@use_args);
}

# Based on "$$" argvalues splits given program args to the "$$"-ones and to the rest
sub extract_dirs_to_list($$) {
	my ($program_ref, $program_args_ref) = @_;

	my @program_args = @{ $program_args_ref };
	my @use_args = ();

	walk_program($program_ref, sub {
			my ($instruction_ref,$instruction_name,$instruction_method,$requires,$produces,$params_ref,$args_ref) = @_;
		
			for my $arg (@{ $args_ref }) {
				if ($arg eq "\$\$") {
					my $value = shift @program_args;
					push @use_args, $value;
				}
			}
	});
	
	return (\@use_args, \@program_args);
}


#######################################

# Utility method for simplified walking throught an program.
sub walk_program($$) {
	my ($program_ref, $instruction_runner) = @_;

	for my $instruction (@{ $program_ref }) {
		my $command = $instruction->{"command"};
		
		my $instruction_name = $command->{"name"};
		my $instruction_method = $command->{"method"};
		my $requires = $command->{"requires"};
		my $produces = $command->{"produces"};
		my $params_ref = $command->{"params"};

		my $args_ref = $instruction->{"arguments"};
	
		$instruction_runner->
			($instruction, $instruction_name, $instruction_method, $requires, $produces, $params_ref, $args_ref);
	}
}
