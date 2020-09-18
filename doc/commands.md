# The commands overview
 This file contains overview of the supported disketo script commands, their parameters, arguments and values.
 _Note: This file was generated by the `gendoc.sh`._
 # The "root" commands
 Each statement has to start with any of this commands:


[filter](#filter) [print](#print) [load](#load) [compute](#compute)

 After that, continue with its declared parameter's values or (sub)commands.

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
**Usage:** `compute for-what`

Computes a meta.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| for-what |  [for-each-file](#for-each-file)  [for-each-dir](#for-each-dir)  |

**Requires:** _nothing_ 
**Produces:** (user specified) 


# compute-custom
**Usage:** `custom as-meta by`

Computes the custom meta.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| as-meta | (meta name) |
| by | (computer function) |

**Requires:** _nothing_ 
**Produces:** (user specified) 


# count-files
**Usage:** `count-files `

Counts of files in each dir.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** resources 
**Produces:** files counts 


# files-stats
**Usage:** `files-stats `

Obtains the stats of the files.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** resources 
**Produces:** files stats 


# filter
**Usage:** `filter what`

Filters by given criteria


| Parameter | Possible value(s) |
| --------- | ----------------- |
| what |  [files](#filter-files)  [dirs](#filter-dirs)  |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# filter-dirs
**Usage:** `dirs matching`

Filters dirs by given criteria


| Parameter | Possible value(s) |
| --------- | ----------------- |
| matching |  [matching-custom-matcher](#matching-custom-matcher)  [matching-pattern](#matching-pattern)  [having-files](#having-files)  |

**Requires:** resources 
**Produces:** _nothing_ 


# filter-files
**Usage:** `files matching`

Filters files by given criteria


| Parameter | Possible value(s) |
| --------- | ----------------- |
| matching |  [matching-custom-matcher](#matching-custom-matcher)  [having-extension](#having-extension)  [matching-pattern](#matching-pattern)  |

**Requires:** resources 
**Produces:** _nothing_ 


# for-each-dir
**Usage:** `for-each-dir what`

For each dir.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| what |  [custom](#compute-custom)  [count-files](#count-files)  |

**Requires:** resources 
**Produces:** _nothing_ 


# for-each-file
**Usage:** `for-each-file what`

For each file.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| what |  [custom](#compute-custom)  [files-stats](#files-stats)  |

**Requires:** resources 
**Produces:** _nothing_ 


# having-extension
**Usage:** `having-extension extension`

Files having the specified extension.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| extension | (extension) |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# having-files
**Usage:** `having-files amount condition`

Directories having specified amount of files matching some condition.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| amount |  [more-than](#more-than)  |
| condition |  [having-extension](#having-extension)  [matching-custom-matcher](#matching-custom-matcher)  [matching-pattern](#matching-pattern)  |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# load
**Usage:** `load roots`

Loads the resources from the specified root folder or the file.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| roots | (the root resources) |

**Requires:** _nothing_ 
**Produces:** resources 


# matching-custom-matcher
**Usage:** `matching-custom-matcher by`

Filters by specified matcher function


| Parameter | Possible value(s) |
| --------- | ----------------- |
| by | (matcher function) |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# matching-pattern
**Usage:** `matching-pattern pattern how`

Matches the given pattern specified way


| Parameter | Possible value(s) |
| --------- | ----------------- |
| pattern | (the pattern) |
| how |  [case-sensitive](#case-sensitive)  [case-insensitive](#case-insensitive)  |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# more-than
**Usage:** `more-than number`

Files having more than specified number of files matching the condition.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| number | (count) |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# print
**Usage:** `print what`

Prints given.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| what |  [files](#print-files)  [dirs](#print-dirs)  [stats](#print-stats)  |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# print-custom
**Usage:** `custom printer`

Prints each resource by the given function.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| printer | (printer function) |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# print-dirs
**Usage:** `dirs how`

Prints dirs.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| how |  [custom](#print-custom)  [with-counts](#print-with-counts)  [only-name](#print-only-name)  [simply](#print-simply)  |

**Requires:** resources 
**Produces:** _nothing_ 


# print-files
**Usage:** `files how`

Prints files.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| how |  [custom](#print-custom)  [simply](#print-simply)  [only-name](#print-only-name)  |

**Requires:** resources 
**Produces:** _nothing_ 


# print-only-name
**Usage:** `only-name `

Prints only the name of the resource.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** _nothing_ 
**Produces:** _nothing_ 


# print-simply
**Usage:** `simply `

Prints each resource by its complete path.


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


# print-with-counts
**Usage:** `with-counts `

Prints each resource and number of its children.


| Parameter | Possible value(s) |
| --------- | ----------------- |
| _no params_ | _no_value(s)_ |

**Requires:** files counts 
**Produces:** _nothing_ 

