#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

package Disketo_Interpreter;
my $VERSION=2.1.1;

use Data::Dumper;
use Disketo_Utils;
use Disketo_Extras;
use Disketo_Instruction_Set;

#######################################
#######################################

#######################################

# Prints usage of the app with script specified
sub print_usage($$$) {
	my ($script_name, $program, $program_args) = @_;
	my @program_args = @{ $program_args };
	
	my $usage = "$script_name ";
	my $count = 0;
	Disketo_Analyser::walk_program($program, sub {
		my ($instruction, $command_name, $command, $args, $resolved_args) = @_;
		my @params = @{ $command->{"params"} };
		
		for (my $i = 0; $i < scalar @params; $i++) {
			my $param = $params[$i];
			my $arg = $args->[$i];

			if ($arg eq "\$\$") {
				$usage = $usage . "<$param of $command_name> ";
				$count++;
			}
		}
	});
	$usage = $usage . "<DIRECTORY/FILE ...>";
	
	print STDERR "Expected at least " . ($count + 1) . " arguments, given " . (scalar @program_args) . "\n";
	Disketo_Utils::usage([], $usage);
}

# Goes throught given program and counts number of "$$" occurences
sub count_params($) {
	my ($program) = @_;

	my $count = 0;
	Disketo_Analyser::walk_program($program, sub {
		my ($instruction, $command_name, $command, $args, $resolved_args) = @_;

		for my $arg (@{ $args }) {
			if ($arg eq "\$\$") {
				$count++;
			}
		}
	});

	return $count;
}


#######################################

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
			my $index;

			my @params = @{ $command->{"params"} };
			my @args = @{ $args };
			for ($index = 0; $index < scalar @params; $index++) {
				my $param = $params[$index];
				my $arg = $args[$index];

				if ($arg eq "\$\$") {
					my $value = shift @args_to_use;
					print STDERR "\t$param := $arg, which is currently $value\n";
				} else {
					print STDERR "\t$param := $arg\n";
				}
			}
		}
	});
}

#######################################

# Runs the given program. What else?
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
			my @args = @{ $instruction->{"arguments"} };
			for my $arg (@args) {
				my $value = undef;
				
				if ($arg eq "\$\$") {
					$value = shift @args_to_use;
				} elsif ($arg =~ "sub ?\{") {
					$value = eval($arg);
					if ($@) {
						print STDERR "Syntax error $@ in $_\n";
					}
				} else {
					$value = $arg;
				}
				
				push @{ $instruction->{"resolved_args"} }, $value;
			}
		}
	});
}
#######################################


# Runs the given program. What else?
sub run_program($$) {
	my ($program, $program_args) = @_;
	
	my ($use_args, $dirs_to_list) = extract_dirs_to_list($program, $program_args);
	my @use_args = @{ $use_args };

	my $context = Disketo_Engine::create_context();
	
	Disketo_Analyser::walk_program($program, sub {
		my ($instruction, $command_name, $command, $args, $resolved_args) = @_;
		my $arguments;
		
		($arguments, $use_args) = prepare_arguments($command_name, $context, $args, $use_args, $dirs_to_list);
		my $command_method = $command->{"method"};
		
		print("Will invoke $command_name with " . join(", ", @{ $arguments }) . " ...\n");
		$command_method->(@{ $arguments });
		print("Executed instruction " . $command_name . ", having " . (scalar (keys %{ $context->{"resources"} })) . " dirs\n");
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


#######################################

# Based on "$$" argvalues splits given program args to the "$$"-ones and to the rest
sub extract_dirs_to_list($$) {
	my ($program, $program_args) = @_;

	my @program_args = @{ $program_args };
	my @use_args = ();

	Disketo_Analyser::walk_program($program, sub {
		my ($instruction, $command_name, $command, $args, $resolved_args) = @_;
		
			for my $arg (@{ $args }) {
				if ($arg eq "\$\$") {
					my $value = shift @program_args;
					push @use_args, $value;
				}
			}
	});
	
	return (\@use_args, \@program_args);
}



