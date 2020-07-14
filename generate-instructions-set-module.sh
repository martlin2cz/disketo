#!/bin/bash
# renders the disketo instruction set module source code
# based on the file template and csv file with supported operations

########################################################################
TEMPLATE_FILE=template_Disketo_Instruction_Set.pm
INSTRUCTIONS_TABLE=disketo-instruction-set.csv
OUTPUT_FILE=Disketo_Instruction_Set.pm
PLACEHOLDER="# GENERATE INSTRUCTIONS HERE"
COMMENT="# instructions generated by $0"
########################################################################

INSTRUCTIONS=""

#https://www.cyberciti.biz/faq/unix-linux-bash-read-comma-separated-cvsfile/
OLDIFS=$IFS
IFS=';'
while read STATEMENT_NAME FUNCTION_NAME REQUIRES PRODUCES PARAMS DOC SAMPLE
do
	if [ $(echo "$STATEMENT_NAME" | grep "#") ] ; then
		continue;
	fi
	
	
	REQUIRES_QUOT=$(echo $REQUIRES | sed -r "s/(([^,]+)(, *|$))/'\2', /g" )
	PARAMS_QUOT=$(echo $PARAMS | sed -r "s/(([^,]+)(, *|$))/'\2', /g" )
	
	INSTRUCTION=" \n\
		# --- $STATEMENT_NAME   $PARAMS -----------------------\n\
		'$STATEMENT_NAME' => { \n\
			'name' => '$STATEMENT_NAME', \n\
			'method' => \\\&Disketo_Instructions::$FUNCTION_NAME, \n\
			'requires' => [$REQUIRES_QUOT], \n\
			'produces' => '$PRODUCES', \n\
			'params' => [$PARAMS_QUOT], \n\
			'doc' => '$DOC' \n\
		}, \n\
		"
		
	echo "Generating $STATEMENT_NAME ..."
	
	INSCTRUCTIONS="$INSCTRUCTIONS $INSTRUCTION"
  
done < $INSTRUCTIONS_TABLE
IFS=$OLDIFS

#sed "s/$PLACEHOLDER/$INSCTRUCTIONS/" < $TEMPLATE_FILE > $OUTPUT_FILE

echo "Saving to file ..."
REPLACEMENT="$COMMENT\\n$INSCTRUCTIONS"

TEMPLATE_CONTENTS=$(<$TEMPLATE_FILE)
TEMPLATE_RENDERED=${TEMPLATE_CONTENTS//$PLACEHOLDER/$REPLACEMENT}

echo -e "$TEMPLATE_RENDERED" > $OUTPUT_FILE

echo "OK"
exit 0


