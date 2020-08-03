#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

use Data::Dumper;
use List::Util;
use Disketo_Utils;
use Disketo_Engine;

#######################################
#######################################

my $context = Disketo_Engine::create_context();
#Disketo_Engine::context_stats($context);
#######################################

my $roots = ["test/dolor", "test/ipsum", "test/lsof.txt"];

Disketo_Engine::load($roots, $context);
#Disketo_Engine::context_stats($context);
#######################################

sub function_for_each_dir($$) {
	my ($dir, $context) = @_;
	return $dir . " is a dir";
}

Disketo_Engine::calculate_for_each_dir(\&function_for_each_dir, "dir meta", $context);
#Disketo_Engine::context_stats($context);
#######################################

sub function_for_each_file($$) {
	my ($file, $context) = @_;
	return $file . " is a file";
}

Disketo_Engine::calculate_for_each_file(\&function_for_each_file, "file meta", $context);
#Disketo_Engine::context_stats($context);
#######################################

sub group_each_dir($$) {
	my ($dir, $context) = @_;
	return substr($dir, 0, 1);
}

Disketo_Engine::group_dirs(\&group_each_dir, "dir groups", $context);
#Disketo_Engine::context_stats($context);
#######################################

sub group_each_file($$) {
	my ($file, $context) = @_;
	my ($ext) = ($file =~ /(\.[^.]+)$/);

	return $ext;
}

Disketo_Engine::group_files(\&group_each_file, "files groups", $context);
#Disketo_Engine::context_stats($context);
#######################################

sub filter_each_dir($$) {
	my ($dir, $context) = @_;
	return length($dir) < 10;
}

Disketo_Engine::filter_dirs(\&filter_each_dir, $context);
#Disketo_Engine::context_stats($context);
#######################################

sub filter_each_file($$) {
	my ($file, $context) = @_;
	my ($ext) = ($file =~ /(\.[^.]+)$/);
	return length($ext) > 1;
}

Disketo_Engine::filter_files(\&filter_each_file, $context);
#Disketo_Engine::context_stats($context);
#######################################
sub output_each_dir($$) {
	my ($dir, $context) = @_;
	return "The dir $dir";
}

Disketo_Engine::print_dirs(\&output_each_dir, $context);
#Disketo_Engine::context_stats($context);
#######################################

sub output_each_file($$) {
	my ($file, $context) = @_;
	return "The file $file";
}

Disketo_Engine::print_files(\&output_each_file, $context);
#Disketo_Engine::context_stats($context);
#######################################

Disketo_Engine::context_stats($context);
