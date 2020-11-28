#!/bin/bash
# Prints the files or dirs matching the specified condition

############ The configuration

# The generated temporary disketo script path
DISKETO_SCRIPT="/tmp/print-matching.ds";

# The files/dirs specifier
WHAT=$1;
shift

# The actual condition
CONDITION=$1
shift

# The root resource(s)
ROOTS=$@

############# Validate the input

if [ "$WHAT" == "" ] || [ "$CONDITION" == "" ] ; then
	echo "Usage: print-matching.sh [files|dirs] [CONDITION] [ROOTS...]"
	echo "Use ./bin/list-statements.pl | grep 'filter [files|dirs]' to obtain the possible CONDITIONs (enter without filter [files|dirs])."
       	echo "For instance: print-matching.sh 'files' 'having-extension \"txt\"' 'test/testing-resources/'"
	echo "              print-matching.sh 'dirs' 'having at-least-one children named \"foo.txt\"' 'test/testing-resources/'"

	exit 1;
fi

if  [ "$WHAT" != "files" ] && [ "$WHAT" != "dirs" ] ; then
	echo "Either the 'files' or 'dirs' has to be choosen"
	exit 2;
fi

############# Generate the script

echo -e "# Prints the $WHAT matching the condition\n"\
"filter $WHAT $CONDITION\n"\
"print $WHAT simply" > $DISKETO_SCRIPT

############ Aaand execute it!

#echo "Starting run.pl $DISKETO_SCRIPT $ROOTS"
./bin/run.pl $DISKETO_SCRIPT $ROOTS


