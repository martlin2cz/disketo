#!/usr/bin/perl

use strict;
BEGIN { unshift @INC, "."; }

package Disketo_Parser;
my $VERSION=3.0.0;

use Data::Dumper;
use Disketo_Utils;
########################################################################

# Implements the parsing procedure. The parsing procedure converts the 
# disketo script file to the disketo script.

########################################################################

# Parses given file. Returns the reference to the script.
sub parse($) {
	my ($script_file) = @_;
	
	my $content = load_file($script_file);
	my $script_ref = parse_content($content);

	return $script_ref;
}

########################################################################

# Loads contents of given file into string
sub load_file($) {
	my ($file) = @_;
	
	my $result = "";
	
	open(F, "<$file") or die("Cannot open script file $file): " . $!);
	while (<F>) {
		$result = $result . $_;
	}
	close (F);

	return $result;
}

########################################################################

# Parses given content into "statements"
sub parse_content($) {
	my ($content) = @_;

	my @tokens = tokenize($content);
	my @result = ([]);
	for my $token (@tokens) {
		if ($token =~ /^#/) { # if line starts with #, ignore it, it's comment
			next;
		}
		elsif ($token eq "\n") { # if newline, push new statement
			if (scalar @{ @result[-1] } > 0) { #if previous line wasn't empty
				push @result, [];
			}
		} 
		else {
			push @{ @result[-1] }, $token; # append the token to the current statement
		}
	}

	if (scalar @{ @result[-1] } == 0) { # if last line was empty, remove it
		pop @result;
	}

	return \@result;
}

# Tokenizes given input string to array of tokens
sub tokenize($) {
	my ($content) = @_;

	my @parts = $content =~ / 
		(?# wrapped in curly backets, to use subs)
		(\{ (?: [^{}]* | (?0) )* \} ) | 
		(?# wrapped in double-quotes)
		(\" [^\"]* \") | 
		(?# regular text, including the numbers and dash)
		( [\w\-]+ ) | 
		(?# the $$ marker)
		( \$\$ ) | 
		(?# pass newlines too)
		( \n ) |
		(?# comments)
		(\# [^\n]* \n) /gx;
		
	my @filtered = grep /(.+)|(\n)/, @parts;
	my @cleaned = map { $_ =~ s/^\"([^\"]*)\"$/\1/r } @filtered;
	my @collapsed = collapse_subs(@cleaned);

	return @collapsed;
}

# All pairs of tokens "sub" and "{ ... }" joins them into one token.
sub collapse_subs(@) {
	my @tokens = @_;
	my @result = ();

	for (my $i = 0; $i < scalar @tokens; $i++) {
		my $token = @tokens[$i];
		if ($token eq "sub") {
			$i++;
			$token = @tokens[$i];
			$token = "sub " . $token;
		}
		push @result, $token;
	}

	return @result;
}

########################################################################
