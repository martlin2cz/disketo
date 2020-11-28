# disketo developper guide

Disketo is implemented in perl. Here are some internal and implementation specific bits.

# The parser mechanism
The parser has four phases:

- Parser (the lexical analyser)
  - read disketo script file into the string
  - split to lines
  - split each line to individual tokens 
- Analyser (the syntactic analyser)
  - converts the rows of tokens into the syntax tree
  - verifies the valid commands
- Preparer (the semantic analyser)
  - resolves the dependencies
  - prepares the values (strips the `"`s and so)
  - evaluates the `sub`s
  - resolves the `$$` and `$$$` markers values
- Interpreter (self-explaining)
  - produces the actual functions (subs) to be executed
  - calls them

_Note:_ Because of that, the `$$` marker cannot contain the _operation name_. Furthermore, it cannot be used inside of the `sub`s (or, in general any other values, like "backup-2020-02-$$.bak". It's just only for the simple atomic values.

# The disketo script syntax

The syntax of the disketo script in the Backus-Naur form:
```
<SCRIPT> ::= <STATEMENTS>

<STATEMENTS> ::= <STATEMENT> "newline" <STATEMENTS> | ""

<STATEMENT> ::= <COMMAND>

<COMMAND> ::= <command_name> <COMMAND_ARGUMENTS>

<COMMAND_ARGUMENTS> ::= <ARGUMENTS>

<ARGUMENTS> ::= <ARGUMENT> <ARGUMENTS> | ""

<ARGUMENT> ::= <COMMAND> | <value>

<command_name> ::= sequence of [a-z0-9\-], but with first char [a-z]

<value> ::= any text wrapped in double quotes (")
          | number
          | text starting "sub {" or "sub{" with matching ending "}"
```

# The commands and methods
All the supported commands are listed in the `Disketo_Instruction_Set` module. It also specifies the links between them and all their properties (including the documentation). Links to module `Disketo_Instructions`, which implements them (in fact the functions (called "methods") producing the functions to be executed). \#AndWeNeedToGoDeeper

The instructions/commands in disketo are as much functional as possible. Thus, `print files` prints files based on the `how?` function. If we print files `with ...`, there gets printed the file path _with_ something. If we print with `size`, it will call the `how?` function on the each file's size to obtain the string reprresentation of the size. The `in-bytes`'s operation will convert the size to string, simply size in bytes. Schematically:
```
print: just delegates to its 'what?' argument
    print files: prints the result of calling the 'how?' argument operation for each file
        with: returns the file path and result of the 'with-what?' argument joined
            with-size: picks the size of each file and applies 'how?' argument to it, returns that
                in-bytes: converts the given size value to string in format "size B"
```

Anyway, this way can be, quite simply, added new commands/operations/or even whole new statements. See the Github issues what's planned to be added, there are plenty of them already.

# Context, resources, metas, dependencies
During the runtime of the disketo script, there is an instance of a _context_ held. The main job for the context is to hold the reference to the actual resources which are processed. This is done via the context field named `resources`. The `resources` field contains hash, where the keys are the directories and their values are references to array of their child resources (not nescessary only the files).

However, the `resources` field is not the only one. Some commands `produces` or `requires` any other fields, for instance "number of the child resources of the each folder" or "date of last change". Theese are called _meta_s. Each meta has its own, unique(!) name and associates to each resource (either just dir or any general resource) some value. Finally, there are commands, which produces the metas and also commands, which requires them. More preciselly, each command has specified which meta(s) it produces and which meta(s) it requires.

Disketo verifies whether such "metas dependencies" are satisfied and if not, it tries to resolve it. If there is exactly one statement producing such meta field, it is automatically inserted into the program.

_Note:_ The statements `print stats` and `print debug-stats` prints the informations about the current context.

# A note about the hypermarker `$$$`
The hypermarker `$$$` inserts as a value all the root resources of the disketo script invocation. However, except for the `load` command, noone else is able to handle this value. Thus, currently, its only usage is to trigger the `load` operation by hand. This is usefull, for instance, when you would like to do load, filter based on condition X, print and then load again, filter based on condition Y and print second time (for example print all "docx" files and then all "xls" files), both in one disketo script.

# Furthermore

Just consult the source code. It's a bit documented, hope it helps.


