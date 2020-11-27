#!/usr/bin/perl
# Prints the script documentation
# (the first n comment lines of the script)

my $script = $ARGV[0];

if ((scalar @ARGV) != 1) {
	die("Usage: scriptman.pl [DISKETO SCRIPT]");
}

open my $handle, '<', $script or die("Cannot open the disketo script file!");

while (my $line = <$handle>) {
	if ($line =~ /\#(.*)/) {
		print("$line");
	} else {
		last;
	}
}

close $handle;


