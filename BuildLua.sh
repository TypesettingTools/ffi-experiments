#!/bin/sh

if [ -z $3 ]; then
	echo "Usage: $0 dir-name ModuleName output.lua"
	exit 1
fi

cd $1
headerInput="$2C.h"
headerOutput="$2C.processed.h"
moonInput="$2.moon"
moonOutput="$2.processed.moon"
luaOutput="$3"

# clean up excess newlines for aesthetics.
cpp -P "$headerInput" | perl -pe "s/^\n$//g" > "$headerOutput"
# drop the processed header into the moonscript file.
cat "$moonInput" | perl -pe "s/___INCLUDE___/`cat $headerOutput`/" > "$moonOutput"
# compile the moonscript file.
moonc -o "../$luaOutput" "$moonOutput" 2> /dev/null
# clean up intermediates.
rm "$headerOutput" "$moonOutput"
