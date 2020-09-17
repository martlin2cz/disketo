#!/usr/bin/perl
use strict;

package Disketo_Instructions; 
my $VERSION=3.0.0;

use Data::Dumper;
use File::Basename;
use Disketo_Utils; 
 
########################################################################
# The implementing module of the Engine. Implements the particular 
# functions, which may be then mapped to instructions.
########################################################################

sub value_of_node($) {
	my ($value_node) = @_;
	if (not exists($value_node->{"value"})) {
		die("Not a value node! " . Dumper($value_node));
	}
	
	my $value = $value_node->{"prepared_value"} ;
	if (not defined($value)) {
		die("Nah, foolish me! Forgot to specify the value!");
	}
	
	return $value;
}

sub child_of_node($$) {
	my ($operation_node, $index) = @_;
	
	my $children = $operation_node->{"arguments"};
	return $children->[$index];
}

sub delegate_to_node($) {
	my ($to_node) = @_;
	
	my $to_operation = $to_node->{"operation"};
	if (not $to_operation) {
		die("Not an operation node!");
	}
	
	my $to_method = $to_operation->{"method"};
	$to_method->($to_node);
}

########################################################################

sub value($$) {
	my ($node, $child_index) = @_;
	my $child = child_of_node($node, $child_index);
	return value_of_node($child);
}


sub delegate($$) {
	my ($node, $child_index) = @_;
	my $child = child_of_node($node, $child_index);
	return delegate_to_node($child);
}

sub is($$$) {
	my ($node, $child_index, $opname) = @_;
	my $child = child_of_node($node, $child_index);
	return $child->{"name"} eq $opname;
}

########################################################################
########################################################################
sub load($) {
	my ($load_node) = @_;
	my $roots = value($load_node, 0);
	
	return sub($) {
		my ($context) = @_;
		Disketo_Engine::load($roots, $context);
	}
}

########################################################################

sub filter($) {
	my ($filter_node) = @_;
	return delegate($filter_node, 0);
}

sub filter_files($) {
	my ($filter_files_node) = @_;

	my $predicate = delegate($filter_files_node, 0);
	return sub($) {
		my ($context) = @_;
		Disketo_Engine::filter_files($predicate, $context);
	};
}

sub filter_dirs($) {
	my ($filter_dirs_node) = @_;

	my $predicate = delegate($filter_dirs_node, 0);
	return sub($) {
		my ($context) = @_;
		Disketo_Engine::filter_dirs($predicate, $context);
	};
}

sub matching_pattern($) {
	my ($matching_pattern_node) = @_;

	my $pattern = value($matching_pattern_node, 0);
	
	if (is($matching_pattern_node, 1, "case-sensitive")) {
		return sub($) {
			my ($resource, $context) = @_;
			return ($resource =~ /$pattern/);
		};
	}
	
	if (is($matching_pattern_node, 1, "case-insensitive")) {
		return sub($) {
			my ($resource, $context) = @_;
			return ($resource =~ /$pattern/i);
		};
	}
	
	die("Unsupported.");
}

sub matching_custom_matcher($) {
	my ($matching_custom_matcher_node) = @_;

	my $predicate = value($matching_custom_matcher_node, 0);
	
	return sub($$) {
		my ($resource, $context) = @_;
		return $predicate->($resource, $context);
	};
}

sub having_extension($) {
	my ($having_extension_node) = @_;

	my $extension = value($having_extension_node, 0);
	
	return sub($$) {
		my ($file, $context) = @_;
		
		return ends_with($file, "." . $extension);
	};
}

sub having_files($) {
	my ($having_files_node) = @_;
	
	my $amount = delegate($having_files_node, 0);
	my $condition = delegate($having_files_node, 1);
	
	return sub($$) {
		my ($dir, $context) = @_;
		my $files_matching = files_of_dir_matching($dir, $condition, $context);
		return $amount->($files_matching, $context)
	};
}


sub more_than($) {
	my ($more_than_node) = @_;
	my $count = value($more_than_node, 0);
	
	return sub($$) {
		my ($files, $context) = @_;
		return (scalar @$files) > $count;
	};
}


########################################################################

sub compute($) {
	my ($compute_node) = @_;
	return delegate($compute_node, 0);
}

sub compute_for_each_file($) {
	my ($compute_for_each_file_node) = @_;

###	return delegate($compute_for_each_file_node, 0);

	my $info = delegate($compute_for_each_file_node, 0);
	my $function = $info->{"function"};
	my $meta_name = $info->{"meta_name"};
	
	return sub($) {
		my ($context) = @_;
		Disketo_Engine::calculate_for_each_file($function, $meta_name, $context);
	};
}

sub compute_for_each_dir($) {
	my ($compute_for_each_dir_node) = @_;
###	return delegate($compute_for_each_dir_node, 0);
	
	my $info = delegate($compute_for_each_dir_node, 0);
	my $function = $info->{"function"};
	my $meta_name = $info->{"meta_name"};
	
	return sub($) {
		my ($context) = @_;
		Disketo_Engine::calculate_for_each_dir($function, $meta_name, $context);
	};
}


sub count_files($) {
	my ($count_files_node) = @_;
	
	my $function = sub($$) {
		my ($dir, $context) = @_;
		my @children = @{ $context->{"resources"}->{$dir} };
		return scalar @children;
	};
	
	return {"function" => $function, "meta_name" => "files count"};
}

sub files_stats($) {
	my ($files_stats_node) = @_;
	
	my $function = sub($$) {
		my ($file, $context) = @_;
		
		return {"file" => $file, "size" => 42}; #TODO
	};
	
	return {"function" => $function, "meta_name" => "files stats"};
}


sub compute_custom($) {
	my ($compute_custom_node) = @_;
	
	my $meta_name = value($compute_custom_node, 0);
	my $computer = value($compute_custom_node, 1);
	
	my $function = sub($$) {
		my ($resource, $context) = @_;
		return $computer->($resource, $context);
	};
	
	return {"function" => $function, "meta_name" => $meta_name};
}


########################################################################


sub print($) {
	my ($print_node) = @_;
	return delegate($print_node, 0);
}

sub print_files($) {
	my ($print_files_node) = @_;

	my $printer = delegate($print_files_node, 0);
	return sub($) {
		my ($context) = @_;
		Disketo_Engine::print_files($printer, $context);
	};
}

sub print_dirs($) {
	my ($print_dirs_node) = @_;

	my $printer = delegate($print_dirs_node, 0);
	return sub($) {
		my ($context) = @_;
		Disketo_Engine::print_dirs($printer, $context);
	};
}

sub print_stats($) {
	my ($print_stats_node) = @_;

	return sub($) {
		my ($context) = @_;
		Disketo_Engine::context_stats($context);
	};
}

sub print_simply($) {
	my ($print_simply_node) = @_;

	return sub($$) {
		my ($resource, $context) = @_;
		return $resource;
	};
}

sub print_only_name($) {
	my ($print_only_name_node) = @_;

	return sub($$) {
		my ($resource, $context) = @_;
		return basename($resource);
	};
}

sub print_with_counts($) {
	my ($print_with_counts_node) = @_;

	return sub($$) {
		my ($resource, $context) = @_;
		my $count = $context->{"files count"}->{$resource};
		return "$resource	$count";
	};
}

sub print_custom($) {
	my ($print_custom_node) = @_;

	my $printer = value($print_custom_node, 0);
	return sub($$) {
		my ($resource, $context) = @_;
		return $printer->($resource, $context);
	};
}

########################################################################

#TODO all the remaining ...

########################################################################
# utils

sub ends_with($$) {
	my ($text, $suffix) = @_;

	return ($suffix eq substr($text, -length($suffix)));
}

sub files_of_dir_matching($$$) {
	my ($dir, $condition, $context) = @_;
	
	my $children = $context->{"resources"}->{$dir};
	my @matching = grep { $condition->($_, $context) } @$children;
	return \@matching;
}
