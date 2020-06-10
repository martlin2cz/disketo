# disketo

An ultimate platform for querying over the hard(/flash/...) drive storage (file systems actually). Allows you to find big files, duplicate directories and contents and many others. Unfortunatelly, most of that you will have program yourself. #DYI

## Technically it's ...

Disketo is in fact platform composed by three layers (perl modules):

 - Disketo_Core
 - Disketo_Extras
 - Disketo_Evaluator

The first one specifies the most internal functions. Built on it, Disketo_Extras, is something like public API for the Core module - specifies callable functions.

Here could I stop, since you could simply **write your querying scripts by calling the Disketo_Extras** ones. Howerver, there is one more. The Evaluator.

The Disketo_Evaluator module implements simple interpreter of **custom scripting language**. The goal of the language (called, suprisingly, "disketo script") is to automate and simplify writing of such perl scripts.   

Thanks to disketo script, you don't have to write

```perl
#!/usr/bin/perl                                                                                                                        

use strict;
BEGIN { unshift @INC, "."; }

use Disketo_Utils;
use Disketo_Extras;

Disketo_Utils::usage(\@ARGV, " <PATTERN> <DIRECTORIES/FILES...>");
if (scalar \@ARGV < 2) {
	Disketo_Utils::usage([], " <PATTERN> <directories/files...>");
}

my $pattern = shift @ARGV;
my @roots = @ARGV;

my $dirs_ref;
$dirs_ref = Disketo_Extras::list_all_directories(@roots);

$dirs_ref = Disketo_Extras::filter_directories_by_pattern($dirs_ref, $pattern);

my $pairs_ref;
($dirs_ref, $pairs_ref) = Disketo_Extras::filter_directories_of_same_name($dirs_ref);

Disketo_Extras::print_directories($dirs_ref, sub {
  my ($dir) = @_;

  my $paired_ref = $pairs_ref->{$dir};

  return $dir . " == " . join(" ", @{ $paired_ref });
});
```

to write script printing matching directories (directories with the same names), but you can use simply:


```perl
filter_directories_by_pattern $$
filter_directories_of_same_name
print_directories sub {
  my ($dir) = @_;

  my $pairs_ref = $previous_ref->[1];
  my $paired_ref = $pairs_ref->{$dir};

  return $dir . " == " . join(" ", @{ $paired_ref });
}
```

All the rest (including listing the directories and priting usage if no arguments specified) is handled by the Evaluator.

# How to use
Disketo script is composed of *statements*. Each *statement* is written at each line and consists of *command name* and its arguments. The *command name* corrresponds to function name from Disketo_Extras module. List of them (so with their parameters) can be achieved by `./run-disketo-script.pl --list-functions`.

The *arguments* can be numbers, quoted strings (this can be regex), perl anonymous sub **or `$$`, which means "pick this value from command line arguments"**. What types of each arguments requires, and to see the preambule of the subs, take look ino to the Extras module code.

In the sub you can use variables `$dirs_ref`, `$stats_ref` and `$previous_ref` holding references to current directories hash, statistics of files hash and result of previous command (some Disketo_Extras functions returns more than filtered list of directories; again, see their source).

Final script is executed by:

```shell
$ ./run-disketo-script.pl script.ds "$$ PARAM 1" "$$ PARAM 2" "DIRECTORY OR FILE 1" "DIRECTORY OR FILE 2"
```

For instance:

```shell
$ ./run-disketo-script.pl scripts/find-duplicate-dirnames.ds "(foo)|(ba[rz])" test/ ls-of-some-backup.txt
```

which produces following output:

```
21:58:05 # Listing all directories in test/, ls-of-some-backup.txt
21:58:05 # Got 11 of them
21:58:05 # Filtering directories matching (foo)|(ba[rz])
21:58:05 # Got 5 of them
21:58:05 # Filtering directories of same name
21:58:05 # Got 4 of them
21:58:05 # Printing directories by printer
test//ipsum/foo == test//lorem/foo
test//lorem/bar == test//other/bar
test//lorem/foo == test//ipsum/foo
test//other/bar == test//lorem/bar
backup//doc == test//project/doc
test//project/doc == backup//doc
21:58:05 # Printed 4 of them
```

This is exactly what the snippets at the beggining does. If you don't provide required parameters, usage will be automatically printed:

```shell
$ ./run-disketo-script.pl scripts/find-duplicate-dirnames.ds "(foo)|(ba[rz])"
Expected at least 2 arguments, given 1
Usage: ./run-disketo-script.pl scripts/find-duplicate-dirnames.ds <pattern of filter_directories_by_pattern> <DIRECTORY/FILE...>
```

You could also run disketo script with flag `--dry-run`, which shows which agruments will be used as what.


# New in version 1.1
 - Added load from file (version 1.1). The input now can be either the directory to list or plain text file with files (recommended absolute paths) one on each line, like:

```
/home/user/libraries/lib.jar
/home/user/libraries/lib-1.1.jar
/home/user/dev/lib/bin/lib.jar
```

- Added simple description to the statements in `--list` and improoved the displaing (version 1.1.2):

```
$ ./run-disketo-script.pl --list
...
print_files	printer
	Prints the files by using the given printer. The printer may be sub($file) returning string to be printed.
```

# TODO
- [x] add support for save/load directory lists to/from text file, to
 1. allow to pause and resume the process for large storages
 2. simplify the debugging
 3. allow user to include/exclude some directories by hand
