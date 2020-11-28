# disketo user guide

This document describes the usage of the disketo.

# tl;dr
- The basic use is `bin/run.pl scrips/disketo-script-file.ds root-directory-to-analyse/`
- Use the remaining scripts in the `bin/` directory to help or troubleshoot your coding. Run them with `--help` or continue reading to see what they do
- There are some sample disketo scripts in the `scripts/` directory

# Running the disketo

The main disketo entrypoint is the `bin/run.pl` script. It executes the _disketo script_ against the specified directories or source files (so-called _root resources_):
```
bin/run.pl scripts/hello-world.ds test/ /tmp/ ~/apps files.txt
```
_Note:_ There are also the _disketo script arguments_ (more about that later). These gets placed in between the disketo script file name and the _root resources_.
_Note:_ If the root resource is directory, disketo recursivelly loads its contents. If the root resource is file, it assumes it is list of paths (each path at a line) to the resources to be working with. Root directories and root files can be combined as desired.
_Note:_ Disketo ignores the unix-like hidden files and directories by default. Currently, there is no way how to avoid that.

# Syntax of the disketo script
_Disketo script_ is text file telling the disketo what to do with the _root resources_.

Each disketo script consists of the so-called _statements_. Each statements (with some exceptions) lays on exactly one line. The line separator is the statements separator as well. There is no `;` at the end of each line/statement or so.

Each _statement_ is a sequence of tokens. The token can be:
- `command-name` (text without quotes, words separated by dash)
- `"text"` (text with double-quotes)
- `sub { return "perl subroutine" }` (this one can stretch over multiple lines)
- the `$$` or `$$$` (the marker and hypermarker, will be described later) 
- or `42.0` (just number).

Tokens are separated by one or more spaces. See:
```
matching-pattern "OK" case-sensitive sub { return "Nope" } having-files     2 and-half
```
_Note:_ Everything after the `#` charater is comment and gets ignored by disketo. Same applies for the blank lines.
_Note:_ Single-quotes **not** supported, use the double-quotes.
_Note:_ Escaped quotes are not (yet) supported as well. Avoid using them or replace them by different escape sequence.

Nextly, each statement has one or more _operations_. An operation is construct `command-name [PARAMETER 1] [PARAMETER 2] ... [PARAMETER n]`. Importantly, an parameter value of the operation can be either the (atomic) _value_ (which means text, sub or number) or any other _operation_. Thus, the operations can recurse. For instance:
```
filter dirs having-files more-than 10 matching pattern "blue" case-sensitive
```
represents following structure:
```
filter
  \- dirs
       \- having files
           \- more-than
               \- 10
           \- matching-pattern
               \- "blue"
               \- case-sensitive
```

_Note:_ Every parameter has a name, which may help to specify which operation or value it requires.
_Note:_ Each parameter of each operation has specified which are its allowed values/operations. For instance, take a `matching-pattern`. Valid value of the first parameter, named `pattern` is _the pattern_ and valid value of the second parameter, named `how` is either the `case-sensitive` or `case-insensitive` operation.
_Note:_ Run the `bin/list-commands.pl` to list all the operations, their parameters and valid values. Run the `bin/list-statements.pl` to see them in action.

# Use of the `$$` and `$$$` marker
You can use the special value `$$` in the disketo script to force acquisition of such value during the runtime, from the command line argument. The root files/directories (gained as the rest after consumption of the arguments specified by the `$$` markers) can be used in the script by the so-called hypermarker `$$$`. However, it is not recommended to use it.

Let's take a script `scripts/dirs-with-files-with-extension.ds`:
```
# Prints directories having at least specified number of files with the specified extension
filter dirs having-files more-than $$ having-extension $$
print dirs simply
```
Running it following way:
```
$ bin/run.pl scripts/dirs-with-files-with-extension.ds 5 "txt" test/ /tmp/
```
Will firstly load all the resources in the `test/` and `/tmp/` folders and then it would use the `5` as a first parameter of the `more-than` operation and the `txt` would be used as the `extension` parameter of the `having-extension` operation.

# Custom functions
If the builtin operations doesn't satisfy your needs, you can quite mostly implement your own way, how to gain things. Just use the particular operation (mostly called `custom`) and provide your own implementation (as a perl sub). For instantace:
```
# Print files but in format "FILENAME, in directory DIR"
print files custom sub {
	my ($file, $context) = @_;
	
	my ($dir,$name) = ($file =~ /^(.*)\/([^\/]+)$/);
	return "$name, in directory $dir";
}
```

_Note:_ The sub gets called with exactly two arguments. The first one is just the particular resource (file or directory) and the second is so-called _context_. The context contains informations about the resources, _metas_ and so. (More info about the context in the developper guide.) The sub may return value corresponding to its usage. See more in the description of the particular operation.

# Troubleshooting

If you have troubles running the script, try one of following. If you are getting syntax errors, pick the particular statement and let it be analysed by the `bin/hint.pl` tool. Insert `"WTF"` (What This Forms?) where you're unsure what belongs to, or what's mising there:
```
$ bin/hint.pl filter files "WTF"
Expected operation (some of: matching-custom-matcher, having-extension, matching-pattern), found: 'WTF' in: statement 1 -> filter -> files.  at Disketo_Analyser.pm line 108.
```
Now you can see you have to put `matching-custom-matcher`, `having-extension` or `matching-pattern` at the `"WTF"` position. Nextly:
```
$ bin/hint.pl filter files having-extension "WTF"
The "WTF" is at position, where (extension) for the 'extension' parameter of the 'having-extension' command is expected.
```
_Note:_ If the "WTF" marker is not recognised, it means there are more errors. Roll back, remove something and verify. The operation must be valid somehow to get the "WTF" marker checked.

Nextly, if the whole script gets parsed, but still there's something wrong, you can print the whole parsed script by calling `bin/parse.pl`. Once you verified all the operations and values are on the righr places, you can dry run the script by running `bin/dry-run.pl`. This would run the script without actually performing anything with the files/dirs, which is handy if you have bilions of bilions of files.

_Note:_ Run theese perl scripts with `-h` or `--help` flags to find out more about them.
_Note:_ Again, the `bin/list-commands.pl` and `bin/list-statements.pl` may be helpful too.

# Output
To separate the output printed by the disketo script runner and the actual data printed by the `print` operations, use the stream redirection:
```
$ bin/run.pl scripts/hello-world.ds test/ > output.txt
21:15:18 # Executing load test/ on 0 directories ...
21:15:18 # Executed  load test/ !
21:15:18 # Executing print files simply on 12 directories ...
21:15:18 # Executed  print files simply !
$ cat output.txt
test//lsof.txt
test//dolor
test//docs
(...)
```

# Final notes
- Due the historical reasons, disketo uses term "files", but that means "everything, what can be inside of the folder, i.e. subdirs, files, links and so". It's more than actual file system file just an indicator to distinguish the _dirs_ (container of other file system entries) and _files_ (leaf nodes in the directory trees). In some cases, there is also the "resources" term in use. That one means both the dirs and files (like "print resource name", no matter whether it is file or dir). To gain just the actual files, insert the `reduce files to-files-only` statement into your script. However, it is recomended to do so just before the print, otherwise it could corrupt some other commands. Sorry for this incovience.
- It is good practise to start each disketo script by a comment describing what the script does. You can then use `utils/scriptman.pl` to output that without need to open the file.
- Dry-run the script before actual run. Verify it is valid and it do can be executed and all the parameters are resolved correctly.
- Since some of the operations can take a while (wallking thousands or milions of directories can take quite a while), I recommend to try your script first on some small subset.
- If you output by the `print files simply` or `print files paths` into the file, such file can be then used as a root resource:
```
$ cat scripts/list-files.ds 
print files path
$ /bin/run.pl scripts/list-files.ds tests/testing-resources/ > list-of-files.txt
(...)
$ ./bin/run.pl scripts/whatever.ds list-of-files.txt
(...)
```
Use that, if you mind some experimenting and re-running. Load one file is much more faster than load thousands of directories!


