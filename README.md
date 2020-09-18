# disketo

An ultimate scripting language for querying over the hard(/flash/...) drive storage (file systems actually). Allows you to find big files, duplicate directories, forgotton backups and many others. Unfortunatelly, many of that you will have program yourself. #DYI

# More info

The general purpose of the disketo is to query over the file systems and storages. To do so, you have to specify what you are looking for. This is done via the so-called **disketo script**s. The disketo script is seqence of instructions to the disketo, what it should look for and how to print that.

In particular, you (disketo) start with something called _root dirs/files_. It's just list of the directories (or file, which will be described later), to work with. It should be, for instance, the root folder of some drive, the user home directory or the _backup_ folder.

Disketo loads into its cache list of all the files and directories in that root directories (or files). What follows next is then up to you. You can restrict, filter the collected resources, for instance only to _PNG_ or _docx_ files. You can express the folders containing "vacation" in its name and having at least 10 photos (_JPGEG_ files). You can (_note: could, in the future, upcoming, version_) find the duplicities. You can print sizes of the files (in Bytes) or directories (number of resources they contain).

Finally, you specify what do you want to output, print, export. With the help of stream redirection, you can simply output to file. Since the results may be quite huge (imagine how much do you have _PNG_ files in your computer, for instance) chunk of files and directories, it is expected to be then automatically processed. For instance, in the excel-like software.

# Hello world disketo script
The very fist disketo script can look like this:
```
# The 'Hello world' disketo script
print files simply
```

Executed like this:
```
$ ./run.pl scripts/hello-world.ds test/
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
Here is disketo script listing all the JPG files named "PICT000000.JPG" up to "PICT999999.JPG", which are located inside of the directory named "photo":
```
# Find photos
filter dirs matching-pattern "$photo^" case-insensitive
filter files having-extension "JPG"
filter files matching-pattern "$PICT[0-9]{6}.JPG^" case-sensitive
print files simply
```

TODO: add more of them.

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

$ ./run.pl scripts/dirs-with-files-with-extension.ds test/
Expected at least 3 script arguments, given 1. The required script arguments are:
  (count) for the 'number' parameter of the 'more-than' command
  (extension) for the 'extension' parameter of the 'having-extension' command
  [ROOT DIR OR FILE 1] ... [ROOT DIR OR FILE n] at Disketo_Preparer.pm line 115.

$ ./run.pl scripts/dirs-with-files-with-extension.ds 5 "txt" test/
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

$ ./run.pl scripts/custom-files-print.ds test/
(...)
file-2.txt, in directory test//ipsum/foo
file-4.txt, in directory test//ipsum/foo
file-1.txt, in directory test//ipsum/foo
(...)
```

## Dependencies
Some commands requires any further informations to be working (for instance, to print the file sizes, the file stats has to be loaded). Disketo (currently) checks whether the required informations is computed by the previous statements, and if not won't start the script execution, until the dependency gets satisfied by the user (inserted the particular statement in the script).

Currently, the only exception is the `load` statement, which loads all the resources of the root resources and which gets automatically pasted into the front of the each disketo script automatically.

# Usage
There are following scripts avaiable:
## run.pl
Runs the actual script.

## dry-run.pl
Simulates the run of the script as it will be executed. Useful to verify the script before execution.

## parse.pl
Parses the disketo script and outputs it structured. Useful for troubleshooting.

## hint.pl
Prints expected item (command name or value and which in particular) is expected in the specified statement.

## list-commands.pl
Prints the list of all the supported commands, theirs valid arguments and values. Usefull as a quick reference.

## list-statements.pl
Prints all the valid combinations of all the supported commands. Usefull for the sample usages of particular command(s).

# More info
See the `doc` folder with further explanation of the syntax, semantic and so.

# New features

T.B.D.

# TODO
- [x] add support for save/load directory lists to/from text file, to
 1. allow to pause and resume the process for large storages
 2. simplify the debugging
 3. allow user to include/exclude some directories by hand
 4. allow to work with hidden resources