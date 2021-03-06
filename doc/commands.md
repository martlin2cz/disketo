# The commands overview
 This file contains overview of the supported disketo script commands, their parameters, arguments and values.
 _Note: This file was generated by the `gendoc.sh`._
 # The "root" commands
 Each statement has to start with any of this commands:


[reduce](#reduce) [print](#print) [group](#group) [load](#load) [execute](#execute) [filter](#filter) [compute](#compute)

 After that, continue with its declared parameter's values or (sub)commands.

# at-least-one
**Usage:** `at-least-one `

Having at least one resource matching the condition.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# bigger-than
**Usage:** `bigger-than what-size? what-unit?`

Filters the resources with size bigger than specified size.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| what-size? | (the size in the specified unit) |
| what-unit? |  [kilobytes](#kilo-bytes)  [megabytes](#mega-bytes)  [bytes](#bytes)  |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# bytes
**Usage:** `bytes `

The size in the Bytes.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# case-insensitive
**Usage:** `case-insensitive `

Matches the pattern ignoring the case


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# case-sensitive
**Usage:** `case-sensitive `

Matches the pattern respecing the case


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# compute
**Usage:** `compute what?`

Computes a meta field.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| what? |  [custom-meta](#compute-custom-meta)  [directories-subtree-counts](#directories-subtree-counts)  [directories-subtree-sizes](#directories-subtree-sizes)  |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# compute-as-meta
**Usage:** `as-meta what-meta?`

Computes the meta field with specified name.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| what-meta? | (the meta field name to be produced) |

**Requires:** _nothing_ 
**Produces:** (user defined) 


# compute-by-appling-custom-function
**Usage:** `by-appling-function what-function?`

Computes the meta field by applying the specified function to each of the resources.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| what-function? | (the function) |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# compute-custom-meta
**Usage:** `custom-meta how? for-each? as-what-meta?`

Computes the custom meta field.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| how? |  [by-appling-function](#compute-by-appling-custom-function)  |
| for-each? |  [to-each-file](#to-each-file)  [to-each-dir](#to-each-dir)  |
| as-what-meta? |  [as-meta](#compute-as-meta)  |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# directories-subtree-counts
**Usage:** `directories-subtree-counts `

Total count of resources in the directory subtree.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** resources 
**Produces:** dir-subtrees-count 


# directories-subtree-sizes
**Usage:** `directories-subtree-sizes `

Total size of subtree of each directory.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** resources file-stats 
**Produces:** dir-subtrees-size 


# dirs-having
**Usage:** `having how-much? of-what?`

Filters dirs having the specified amount of element in the given group.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| how-much? |  [less-than](#less-than)  [none](#none)  [more-than](#more-than)  [at-least-one](#at-least-one)  |
| of-what? |  [of-the-same](#dirs-of-the-same)  [children](#dirs-having-children)  |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# dirs-having-children
**Usage:** `children matching-what?`

Filters dirs matching specified condition of its children.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| matching-what? |  [having](#files-having)  [matching-pattern](#matching-pattern)  [matching-custom-matcher](#matching-custom-matcher)  [having-extension](#having-extension)  [named](#named)  [files](#dirs-having-children-files)  |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# dirs-having-children-files
**Usage:** `files `

Filters just on the children files as they are.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# dirs-of-the-same
**Usage:** `of-the-same which-group?`

Filters resources based on the group of the same resources.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| which-group? |  [custom-group](#with-the-same-of-custom)  [name](#dirs-with-the-same-name)  [name-and-subtree-count](#dirs-with-the-same-name-and-subtree-count)  [name-and-subtree-size](#dirs-with-the-same-name-and-subtree-size)  |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# dirs-subtree-sized
**Usage:** `with-subtree-size what-size?`

Filters dirs with subtree size matching specified condition.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| what-size? |  [bigger-than](#bigger-than)  [smaller-than](#smaller-than)  |

**Requires:** dir-subtrees-size 
**Produces:** _nothing_ 


# dirs-with-the-same-name
**Usage:** `name `

Matches the dirs which have the same name.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** dirs-with-same-name 
**Produces:** _nothing_ 


# dirs-with-the-same-name-and-subtree-count
**Usage:** `name-and-subtree-count `

Matches the dirs which have the same name and subtree resources count.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** dirs-with-same-name-and-subtree-count 
**Produces:** _nothing_ 


# dirs-with-the-same-name-and-subtree-size
**Usage:** `name-and-subtree-size `

Matches the dirs which have the same name and total subtree resources size.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** dirs-with-same-name-and-subtree-size 
**Produces:** _nothing_ 


# execute
**Usage:** `execute what?`

Executes some function once during the process.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| what? | (operation to perform) |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# files-having
**Usage:** `having how-much? of-what?`

Filters files having the specified amount of element in the given group.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| how-much? |  [more-than](#more-than)  [at-least-one](#at-least-one)  [less-than](#less-than)  [none](#none)  |
| of-what? |  [of-the-same](#files-of-the-same)  |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# files-of-the-same
**Usage:** `of-the-same which-group?`

Filters files having given group.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| which-group? |  [name-and-size](#files-with-the-same-name-and-size)  [name](#files-with-the-same-name)  [custom-group](#with-the-same-of-custom)  |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# files-sized
**Usage:** `with-size what-size?`

Filters files with size matching specified condition.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| what-size? |  [bigger-than](#bigger-than)  [smaller-than](#smaller-than)  |

**Requires:** file-stats 
**Produces:** _nothing_ 


# files-stats
**Usage:** `files-stats `

Loads the stats (file sizes, dates of modifications, ... ) of the files.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** resources 
**Produces:** file-stats 


# files-with-the-same-name
**Usage:** `name `

Matches the files which have the same name.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** files-with-same-name 
**Produces:** _nothing_ 


# files-with-the-same-name-and-size
**Usage:** `name-and-size `

Matches the dirs which have the same name and size.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** files-with-same-name-and-size 
**Produces:** _nothing_ 


# filter
**Usage:** `filter what?`

Filters the resources by given criteria.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| what? |  [files](#filter-files)  [dirs](#filter-dirs)  |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# filter-dirs
**Usage:** `dirs matching-what?`

Filters dirs by given criteria.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| matching-what? |  [with-subtree-size](#dirs-subtree-sized)  [named](#named)  [having](#dirs-having)  [matching-pattern](#matching-pattern)  [matching-custom-matcher](#matching-custom-matcher)  |

**Requires:** resources 
**Produces:** _nothing_ 


# filter-files
**Usage:** `files matching-what?`

Filters files by given criteria


| Parameter | Possible value(s) |
| --------- | ----------------- |
| matching-what? |  [named](#named)  [having-extension](#having-extension)  [matching-pattern](#matching-pattern)  [with-size](#files-sized)  [matching-custom-matcher](#matching-custom-matcher)  [having](#files-having)  |

**Requires:** resources 
**Produces:** _nothing_ 


# group
**Usage:** `group what?`

Computes a group with the resources groupped by some groupper


| Parameter | Possible value(s) |
| --------- | ----------------- |
| what? |  [dirs](#group-dirs)  [files](#group-files)  |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# group-as-meta
**Usage:** `as-meta what-meta?`

Groups it as a group with specified name.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| what-meta? | (the group meta field name to be produced) |

**Requires:** _nothing_ 
**Produces:** (user defined) 


# group-by-custom
**Usage:** `by-custom-groupper what-function? as-meta?`

Groups the resources by the specified groupper function.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| what-function? | (the groupper function) |
| as-meta? |  [as-meta](#group-as-meta)  |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# group-dirs
**Usage:** `dirs by-what?`

Groups the dirs by the given groupper.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| by-what? |  [by-name-and-subtree-size](#group-dirs-by-name-and-subtree-size)  [by-name-and-subtree-count](#group-dirs-by-name-and-subtree-count)  [by-name-and-children-count](#group-dirs-by-name-and-children-count)  [by-custom-groupper](#group-by-custom)  [by-name](#group-dirs-by-name)  |

**Requires:** resources 
**Produces:** _nothing_ 


# group-dirs-by-name
**Usage:** `by-name `

Groups the dirs by their name.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** _nothing_ 
**Produces:** dirs-with-same-name 


# group-dirs-by-name-and-children-count
**Usage:** `by-name-and-children-count `

Groups the directories by their name and the number of child resources.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** _nothing_ 
**Produces:** dirs-with-same-name-and-children-count 


# group-dirs-by-name-and-subtree-count
**Usage:** `by-name-and-subtree-count `

Groups the directories by their name and the total number of ancesting resources.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** dir-subtrees-count 
**Produces:** dirs-with-same-name-and-subtree-count 


# group-dirs-by-name-and-subtree-size
**Usage:** `by-name-and-subtree-size `

Groups the directories by their name and the total size of ancesting resources.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** dir-subtrees-size 
**Produces:** dirs-with-same-name-and-subtree-size 


# group-files
**Usage:** `files by-what?`

Groups the files by the given groupper.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| by-what? |  [by-custom-groupper](#group-by-custom)  [by-name](#group-files-by-name)  [by-name-and-size](#group-files-by-name-and-size)  |

**Requires:** resources 
**Produces:** _nothing_ 


# group-files-by-name
**Usage:** `by-name `

Groups the files by their names.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** _nothing_ 
**Produces:** files-with-same-name 


# group-files-by-name-and-size
**Usage:** `by-name-and-size `

Groups the files by their name and size.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** file-stats 
**Produces:** files-with-same-name-and-size 


# having-extension
**Usage:** `having-extension which-extension?`

Files having the specified extension.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| which-extension? | (extension) |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# kilo-bytes
**Usage:** `kilobytes `

The size in the kiloBytes.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# less-than
**Usage:** `less-than what-number?`

Having less than specified number of resources matching the condition.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| what-number? | (count) |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# load
**Usage:** `load what?`

Loads specified data from the disk.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| what? |  [resources](#load-resources)  [files-stats](#files-stats)  |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# load-resources
**Usage:** `resources what-roots?`

Loads the resources from the specified root folder(s) or the file.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| what-roots? | (the root resource or resources) |

**Requires:** _nothing_ 
**Produces:** resources 


# matching-custom-matcher
**Usage:** `matching-custom-matcher by-what?`

Filters by specified matcher function


| Parameter | Possible value(s) |
| --------- | ----------------- |
| by-what? | (matcher function) |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# matching-pattern
**Usage:** `matching-pattern pattern? how?`

Matches the given pattern specified way.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| pattern? | (the pattern) |
| how? |  [case-insensitive](#case-insensitive)  [case-sensitive](#case-sensitive)  |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# mega-bytes
**Usage:** `megabytes `

The size in the megaBytes.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# more-than
**Usage:** `more-than what-number?`

Having more than specified number of resources matching the condition.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| what-number? | (count) |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# named
**Usage:** `named what-name?`

Resources having the specified name.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| what-name? | (the resource name) |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# none
**Usage:** `none `

Having exactly zero of resources matching the condition.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# print
**Usage:** `print what?`

Prints given.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| what? |  [debug-stats](#print-debug-stats)  [stats](#print-stats)  [dirs](#print-dirs)  [files](#print-files)  |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# print-custom
**Usage:** `custom how?`

Prints each resource by the given function.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| how? | (printer function) |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# print-custom-group
**Usage:** `custom-group what-group?`

Prints the resources with resources in the same group specified by the given groupper function.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| what-group? | (the group meta field name required) |

**Requires:** (user defined) 
**Produces:** _nothing_ 


# print-debug-stats
**Usage:** `debug-stats `

Prints the more precise informations about the current context.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# print-dir-with-children-count
**Usage:** `count `

Prints each directory and number of its children.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# print-dir-with-children-custom
**Usage:** `custom how?`

Prints each directory and by custom printer also its children resources.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| how? | (the children files printer function) |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# print-dir-with-children-names
**Usage:** `names `

Prints each directory and names of its children resources.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# print-dir-with-children-paths
**Usage:** `paths `

Prints each directory and paths of its children resources.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# print-dir-with-subtree
**Usage:** `subtree subtree-what?`

Prints the directory and something of its subtree


| Parameter | Possible value(s) |
| --------- | ----------------- |
| subtree-what? |  [size](#print-dir-with-subtree-size)  [resources-count](#print-dir-with-subtree-count)  |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# print-dir-with-subtree-count
**Usage:** `resources-count `

Prints each directory and number of resources in its subtree.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# print-dir-with-subtree-size
**Usage:** `size how?`

Prints each directory and total size of resources in its subtree.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| how? |  [human-readable](#print-size-human-readable)  [in-bytes](#print-size-in-bytes)  |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# print-dirs
**Usage:** `dirs how?`

Prints dirs.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| how? |  [only-name](#print-only-name)  [with](#print-dirs-with)  [simply](#print-simply)  [path](#print-path)  [custom](#print-custom)  |

**Requires:** resources 
**Produces:** _nothing_ 


# print-dirs-with
**Usage:** `with with-what?`

Prints for each dir its path and specified extra information.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| with-what? |  [children](#print-with-children)  [meta](#print-with-meta)  [dirs-of-the-same](#print-dirs-with-its-group)  [subtree](#print-dir-with-subtree)  |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# print-dirs-with-its-group
**Usage:** `dirs-of-the-same what-groupper?`

Prints the dirs with all the resources it same group.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| what-groupper? |  [name-and-subtree-size](#print-with-same-name-and-subtree-size)  [name-and-children-count](#print-with-same-name-and-children-count)  [name-and-subtree-resources-count](#print-with-same-name-and-subtree-resources-count)  [name](#print-dirs-with-same-name)  [custom-group](#print-custom-group)  |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# print-dirs-with-same-name
**Usage:** `name `

Prints the dirs with the same name as the current dir.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** dirs-with-same-name 
**Produces:** _nothing_ 


# print-files
**Usage:** `files how?`

Prints files.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| how? |  [only-name](#print-only-name)  [custom](#print-custom)  [path](#print-path)  [with](#print-files-with)  [simply](#print-simply)  |

**Requires:** resources 
**Produces:** _nothing_ 


# print-files-with
**Usage:** `with with-what?`

Prints for each file its path and specified extra information.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| with-what? |  [files-of-the-same](#print-files-with-its-group)  [size](#print-files-with-size)  [meta](#print-with-meta)  |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# print-files-with-its-group
**Usage:** `files-of-the-same what-groupper?`

Prints the files with all the files of the specified same property.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| what-groupper? |  [name-and-size](#print-files-with-same-name-and-size)  [custom-group](#print-custom-group)  [name](#print-files-with-same-name)  |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# print-files-with-same-name
**Usage:** `name `

Prints the files with the same name as the current file.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** files-with-same-name 
**Produces:** _nothing_ 


# print-files-with-same-name-and-size
**Usage:** `name-and-size `

Prints the resources with the same name and size as the current resource.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** files-with-same-name-and-size 
**Produces:** _nothing_ 


# print-files-with-size
**Usage:** `size how?`

Prints the files and their size.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| how? |  [in-bytes](#print-size-in-bytes)  [human-readable](#print-size-human-readable)  |

**Requires:** file-stats 
**Produces:** _nothing_ 


# print-only-name
**Usage:** `only-name `

Prints only the name of the resource.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# print-path
**Usage:** `path `

Prints complete path of each resource.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# print-simply
**Usage:** `simply `

Prints just the path of each resource (an alias for the print-path).


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# print-size-human-readable
**Usage:** `human-readable `

Prints the file size automatically in the B, kB, MB or GB based on its actual value.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# print-size-in-bytes
**Usage:** `in-bytes `

Prints the file size in Bytes.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# print-stats
**Usage:** `stats `

Prints the current context stats.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# print-with-children
**Usage:** `children children-what?`

Prints each directory and something of its children


| Parameter | Possible value(s) |
| --------- | ----------------- |
| children-what? |  [paths](#print-dir-with-children-paths)  [count](#print-dir-with-children-count)  [names](#print-dir-with-children-names)  [custom](#print-dir-with-children-custom)  |

**Requires:** resources 
**Produces:** _nothing_ 


# print-with-meta
**Usage:** `meta which-meta?`

Prints the resource and its corresponding meta field value.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| which-meta? | (the meta field name required) |

**Requires:** (user defined) 
**Produces:** _nothing_ 


# print-with-same-name-and-children-count
**Usage:** `name-and-children-count `

Prints the dirs with the same name and children count as the current dir.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** dirs-with-same-name-and-children-count 
**Produces:** _nothing_ 


# print-with-same-name-and-subtree-resources-count
**Usage:** `name-and-subtree-resources-count `

Prints the dirs with the same name and subtree resources count as the current dir.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** dirs-with-same-name-and-subtree-count 
**Produces:** _nothing_ 


# print-with-same-name-and-subtree-size
**Usage:** `name-and-subtree-size `

Prints the dirs with the same name and subtree size as the current dir.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** dirs-with-same-name-and-subtree-size 
**Produces:** _nothing_ 


# reduce
**Usage:** `reduce what?`

Reduces the specified resources to specified subset of them.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| what? |  [files](#reduce-files)  |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# reduce-files
**Usage:** `files to?`

Reduces the files.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| to? |  [to-files-only](#reduce-files-to-files-only)  [to-dirs-only](#reduce-files-to-dirs-only)  |

**Requires:** resources 
**Produces:** _nothing_ 


# reduce-files-to-dirs-only
**Usage:** `to-dirs-only `

Reduces the files to contain only the actual dirs.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# reduce-files-to-files-only
**Usage:** `to-files-only `

Reduces the files to contain only the actual files.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# smaller-than
**Usage:** `smaller-than what-size? what-unit?`

Filters the resources with size smaller than specified size.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| what-size? | (the size in the specified unit) |
| what-unit? |  [bytes](#bytes)  [megabytes](#mega-bytes)  [kilobytes](#kilo-bytes)  |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# to-each-dir
**Usage:** `to-each-dir `

Computes the new meta for each directory.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** resources 
**Produces:** _nothing_ 


# to-each-file
**Usage:** `to-each-file `

Computes the new meta for each file.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** resources 
**Produces:** _nothing_ 


# with-the-same-of-custom
**Usage:** `custom-group what-group?`

Matches the resources which have the specified amount of the resources with the specified custom groupper.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| what-group? | (the group meta field name required) |

**Requires:** (user defined) 
**Produces:** _nothing_ 


