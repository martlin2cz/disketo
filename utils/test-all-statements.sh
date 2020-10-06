#!/bin/bash
# Runs all the statements as a separate, one-lined disketo scripts

STATEMENTS_FILE="doc/all-statements.ds"
STATEMENTS_MOD_FILE="/tmp/statements-mod.ds"
DISKETO_SCRIPT_FILE="/tmp/disketo-script.ds"
TEST_RESOURCES_DIR="tests/testing-resources"


# Replace the statements values specifiers by actual values (subs or strings)
cat $STATEMENTS_FILE  \
	| sed -E 's/\(([^\)]*)((function)|(operation))([^\)]*)\)/sub { shift @_; }/g' \
	| sed -E 's/\(([^\)]*)((number)|(count))([^\)]*)\)/42/g' \
	| sed -E 's/\((.+)\)/"\1"/g' \
	> $STATEMENTS_MOD_FILE

# Prepare the list of failuar ones
FAILS=""

# Run each of them
while IFS= read -r LINE ; do
	echo "=== TESTING $LINE ==="
	echo $LINE > $DISKETO_SCRIPT_FILE
	./bin/run.pl $DISKETO_SCRIPT_FILE $TEST_RESOURCES_DIR > /dev/null

	if [ $? -ne 0 ] ; then
		FAILS="$FAILS\n$LINE"
	fi
done < $STATEMENTS_MOD_FILE

echo -e "Following failed:$FAILS"
