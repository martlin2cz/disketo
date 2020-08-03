#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

package Disketo_Interpreter;
my $VERSION=2.2.0;

use Data::Dumper;
use Disketo_Utils;
use Disketo_Extras;
use Disketo_Instruction_Set;

########################################################################

# Does the actual job with the disketo program. Prints usage, prints 
# the instructions, or runs the program itself.
# This includes the processing of the actual script arguments.

########################################################################

# Creates (as string) usage of the app with script specified. 
# If program_args specified, checks its count as well.
sub create_usage($$$) {
	my ($script_name, $program, $program_args) = @_;
	my @program_args = @{ $program_args } if $program_args;
	
	my $usage = "$script_name ";
	
	my $wilds = collect_wildcarded_args($program);
	for my $wild_obj (@{ $wilds }) {
		my $command_name = $wild_obj->{"command"}->{"name"};
		my $param = $wild_obj->{"param"};
		
		$usage = $usage . "<$param of $command_name> ";
	}
	$usage = $usage . "<DIRECTORY/FILE ...>";
	$usage = $usage . "\n";
	if ($program_args) {
		# + 1 at least 1 root file/dir
		my $expected_count = (scalar @{ $wilds }) + 1; 
		my $given_count = scalar @program_args;
		if ($given_count < $expected_count) {
			$usage = $usage . "Script expects at least " . $expected_count . " arguments, given " . $given_count . "\n";
		}
	}
	return $usage;
}

# Goes throught given program and collects the "$$" arguments' params
sub collect_wildcarded_args($) {
	my ($program) = @_;

	my @params = ();
	Disketo_Analyser::walk_program($program, sub {
		my ($instruction, $command_name, $command, $args, $resolved_args) = @_;

		walk_params($instruction, sub($$$) {
			my ($param, $arg, $resolved_arg) = @_;
			
			if ($arg eq "\$\$") {
				my $arg_obj = {"command" => $command, "param" => $param };
				push @params, $arg_obj;
			}
		});
	});

	return \@params;
}

########################################################################

# Prints the program (with arguments)
sub print_program($$) {
	my ($program, $program_args) = @_;
	my @program_args = @{ $program_args };

	my ($use_args, $dirs_to_list) = extract_dirs_to_list($program, $program_args);	
	my @args_to_use = @{ $use_args };

	Disketo_Analyser::walk_program($program, sub {
		my ($instruction, $command_name, $command, $args, $resolved_args) = @_;

		print STDERR "Will invoke $command_name:\n";
		if ($command_name eq "load") {
			print STDERR "\t with directories " . join(", ", @{ $dirs_to_list }) . "\n";
		} else {
			walk_params($instruction, sub($$$) {
				my ($param, $arg, $resolved_arg) = @_;

				if ($arg eq "\$\$") {
					my $value = shift @args_to_use;
					print STDERR "\t$param := $arg, which is currently $value\n";
				} else {
					print STDERR "\t$param := $arg\n";
				}
			});
		}
	});
}

########################################################################

# Prepares the program to execute (or print)
sub prepare($$) {
	my ($program, $program_args) = @_;
	
	$program = insert_loads($program, $program_args);
	$program = resolve_args($program, $program_args);
	
	return $program;
}

# For each dir_to_list inserts a load instruction.
sub insert_loads($$) {
	my ($program, $program_args) = @_;
	my @program = @{ $program };

	my ($use_args, $dirs_to_list) = extract_dirs_to_list($program, $program_args);	
	my $commands = Disketo_Instruction_Set::commands();
	
	for my $dir_to_list ( reverse @{ $dirs_to_list} ) {
		my $statement = ["load", $dir_to_list];
		my $instruction = Disketo_Analyser::compute_instruction($statement, $commands);
		unshift @program, $instruction;
	}

	return \@program;
}

# Computes the resolved_args field of each instruction.
sub resolve_args($$) {
	my ($program, $program_args) = @_;
	my @program_args = @{ $program_args };

	my ($use_args, $dirs_to_list) = extract_dirs_to_list($program, $program_args);	
	my @args_to_use = @{ $use_args };

	Disketo_Analyser::walk_program($program, sub {
		my ($instruction, $command_name, $command, $args, $resolved_args) = @_;
		
		if ($command_name eq "load") {
			$instruction->{"resolved_args"} = [ $dirs_to_list ];
		} else {
			walk_params($instruction, sub($$$) {
				my ($param, $arg, $resolved_arg) = @_;
				my $value = undef;
				
				if ($arg eq "\$\$") {
					$value = shift @args_to_use;
				} elsif ($arg =~ "sub ?\{") {
					$value = eval($arg);
					if ($@) {
						print STDERR "Syntax error $@ in $arg\n";
					}
				} else {
					$value = $arg;
				}
				
				push @{ $instruction->{"resolved_args"} }, $value;
			});
		}
	});
	
	return $program;
}

########################################################################

# Runs the given program. What else?
sub run_program($$) {
	my ($program, $program_args) = @_;
	
	my ($use_args, $dirs_to_list) = extract_dirs_to_list($program, $program_args);
	my @use_args = @{ $use_args };

	my $context = Disketo_Engine::create_context();
	
	Disketo_Analyser::walk_program($program, sub {
		my ($instruction, $command_name, $command, $args, $resolved_args) = @_;
		my $arguments;
		
		($arguments, $use_args) = prepare_method_arguments($command_name, $context, $args, $use_args, $dirs_to_list);
		my $command_method = $command->{"method"};
		
		print("Will invoke $command_name with " . join(", ", @{ $arguments }) . " ...\n");
		$command_method->(@{ $arguments });
		print("Executed instruction " . $command_name . ", having " . (scalar (keys %{ $context->{"resources"} })) . " dirs\n");
	});
}

# Prepares the arguments to the command method.
sub prepare_method_arguments($) {
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


########################################################################

# Based on "$$" argvalues splits given program args to the "$$"-ones and to the rest
sub extract_dirs_to_list($$) {
	my ($program, $program_args) = @_;

	my @program_args = @{ $program_args };
	my @use_args = ();

	Disketo_Analyser::walk_program($program, sub {
		my ($instruction, $command_name, $command, $args, $resolved_args) = @_;
		
			walk_params($instruction, sub($$$) {
				my ($param, $arg, $resolved_arg) = @_;
				
				if ($arg eq "\$\$") {
					my $value = shift @program_args;
					push @use_args, $value;
				}
			});
	});
	
	return (\@use_args, \@program_args);
}

# Iterates over the params and args of the given instruction
sub walk_params($$) {
	my ($instruction, $runner) = @_;
	my $command = $instruction->{"command"};

	my @params = @{ $command->{"params"} };
	my @args = @{ $instruction->{"arguments"} };
	my @resolved_args = @{ $instruction->{"resolved_arguments"} } 
							if exists $instruction->{"resolved_arguments"};
	
	my $index;
	for ($index = 0; $index < scalar @params; $index++) {
		my $param = $params[$index];
		my $arg = $args[$index];
		my $resolved_arg = $resolved_args[$index];
	
		$runner->($param, $arg, $resolved_arg);
	}
}

