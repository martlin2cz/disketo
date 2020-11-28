# disketo

An ultimate scripting language for querying over the hard(/flash/...) drive storage (file systems and storages in general). Allows you to find big files, duplicate directories, forgotton backups and many others. Unfortunatelly, many of that you will have _code_ yourself. #DYI

# More info

The general purpose of the disketo is to query over the file systems and storages. To do so, you have to specify what you are looking for. This is done via the so-called **disketo script**s. The disketo script is seqence of instructions to the disketo, _what_ it should look for and _how_ to print that.

In particular, you (disketo) start with something called _root dirs/files_. It's just list of the directories (or file listing all the files), to work with. It should be, for instance, the root folder of some drive, the user home directory or the `backup` folder.

Disketo firstly loads list of all the files and directories in that root directories (or files). What follows next is then up to you. You can restrict, filter the collected resources, for instance only to _PNG_ or _docx_ files. You can express the folders containing "vacation" in its name and having at least 10 photos (_JPEG_ files). You can find the duplicities. You can print sizes of the files or directories (total size of the files it contains).

Finally, you specify what do you want to output, print, export. The collected and filtered resources gets outputted, each one at each line. So you can simply pipe the output of disketo to file and/or possibly use some other tools like `awk`, `column`, `diff` or even some GUI table processor, like the `excel`. 

# Hello world disketo script
The very fist disketo script can look like this:
```
# The 'Hello world' disketo script
print files simply
```

Executed like this:
```
$ bin/run.pl scripts/hello-world.ds test/
19:07:22 # Executing load test/ on 0 directories ...
19:07:22 # Executed load test/ !
19:07:22 # Executing print files simply on 12 directories ...
test//lorem/bar/file-4.txt
test//lorem/bar/file-5.txt
(...)
test//docs/jitka.doc
19:07:22 # Executed print files simply!
```

# Another sample scripts
Here is disketo script listing all the JPG files named "PICT000000.JPG" up to "PICT999999.JPG", which are located inside of the directories named "vacation", "vacations", "VACATION PHOTOS", "summer vacation 2020" and so:
```
# Find photos from the vacation
filter dirs matching-pattern "$vacation^" case-insensitive
filter files having-extension "JPG"
filter files matching-pattern "$PICT[0-9]{6}.JPG^" case-sensitive
print files simply
```
Do you wan to find biggest files? Try to filter out small ones and print files bigger than specified size (here the 100MB) and then sort the output by the size:
```
# Prints the files bigger than specified size in megabytes

# Filter them
filter files with-size bigger-than $$ megabytes

# and print
print files with size human-readable
```
Executed like this:
```
$ bin/run.pl scripts/files-bigger-than.ds 100 tests/testing-resources/ | awk '{ p=$1; $1=$2; $2=$3; $3=p; print; }' | sort -n
19:42:50 # Executing load resources tests/testing-resources/ ...
19:42:50 # Executed  load resources tests/testing-resources/ !
19:42:50 # Executing load files-stats on 11 directories ...
19:42:50 # Executed  load files-stats !
19:42:50 # Executing filter files with-size bigger-than 100 megabytes on 11 directories ...
19:42:50 # Executed  filter files with-size bigger-than 100 megabytes !
19:42:50 # Executing print files with size human-readable on 11 directories ...
485 MB tests/testing-resources//something-giant
475 MB tests/testing-resources//something-little-less-giant
(...)
19:42:50 # Executed  print files with size human-readable !
```

This script prints all the directories and their "evil twins" (the directories with same name and number of files in it):
```
# Prints the directories which has the same name and subtree count
filter dirs having at-least-one of-the-same name-and-subtree-count
print dirs with dirs-of-the-same name-and-subtree-count
```


# Features
## Comments
Everything followed by the `#` gets ignored. Same for the empty or blank lines.

## Output
The actual output (the printed files and dirs) can be distingushed from the progress informations by redirection. The output prints to STDOUT, the rest to the STDERR.

## The `$$` marker
When you replace any value by the `$$`, it has to be specified during the runtime. See:
```
$ cat scripts/dirs-with-files-with-extension.ds
# Prints directories having at least specified number of files with the specified extension
filter dirs having-files more-than $$ having-extension $$
print dirs simply

$ bin/run.pl scripts/dirs-with-files-with-extension.ds test/
Expected at least 3 script arguments, given 1. The required script arguments are:
  (count) for the 'number' parameter of the 'more-than' command
  (extension) for the 'extension' parameter of the 'having-extension' command
  [ROOT DIR OR FILE 1] ... [ROOT DIR OR FILE n] at Disketo_Preparer.pm line 115.

$ bin/run.pl scripts/dirs-with-files-with-extension.ds 5 "txt" test/
(...)
```
Will print all directories having at least 5 `txt` files.

## Customisation
If your desired feature is not supported, you can quite allways provide your solution via the custom perl sub:
```
$ cat scripts/custom-files-print.ds
# Print files but in format "FILENAME, in directory DIR"
print files custom sub {
	my ($file, $context) = @_;
	
	my ($dir,$name) = ($file =~ /^(.*)\/([^\/]+)$/);
	return "$name, in directory $dir";
}

$ bin/run.pl scripts/custom-files-print.ds test/
(...)
file-2.txt, in directory test//ipsum/foo
file-4.txt, in directory test//ipsum/foo
file-1.txt, in directory test//ipsum/foo
(...)
```

## Dependencies
Some commands requires any further informations to be working (for instance, to print the file sizes, the file stats has to be loaded). Disketo automatically inserts the particular commands to the script which produces theese informations. You can, of course trigger them manually, but there's need for that only in cases it cannot be resolved algorithmically (typically, when using custom subs).

# Usage
There are following scripts avaiable:
## bin/run.pl
Runs the actual script.

## bin/dry-run.pl
Simulates the run of the script as it will be executed. Useful to verify the script before execution.

## bin/parse.pl
Parses the disketo script and outputs it structured. Useful for troubleshooting.

## bin/hint.pl
Prints expected item (command name or value and which in particular) is expected in the specified statement.

## bin/list-commands.pl
Prints the list of all the supported commands, theirs valid arguments and values. Usefull as a quick reference.

## bin/list-statements.pl
Prints all the valid combinations of all the supported commands. Usefull for the sample usages of particular command(s).

And also:
## utils/scriptman.pl
Prints the doc/man of the disketo script (comments the script starts with).

## utils/print-matching.pl
An utility to execute filter&print directly from command line, without need to create disketo script as a file. For instance:
```
utils/print-matching.sh 'files' 'having-extension "txt"' 'test/testing-resources/'
```
# More info
See the `doc/` folder with further explanation of the syntax, semantic and so.

# New features

- It have been added various commands to the instruction set. Take a look into the `doc/` folder or run `bin/list-all-commands.pl` to see.
- Added the dependency resolution. All the `load files-stats` and `group files by ...` commands are now getting added automatically.
- Added some more utility scripts.

# TODO
See the issues.
