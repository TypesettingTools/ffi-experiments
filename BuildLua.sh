#!/bin/sh

if [ -z $2 ]; then
	echo "Usage: $0 input_file output_file [input2 output2 ...]"
	echo "e.g.: $0 'threaded-libcurl/DownloadManager.moon' 'DownloadManager.lua'"
	exit 0
fi

while [[ "$#" -ge 2 ]]; do
	moonInput="$1"
	moonInputBase=`basename "$moonInput"`

	moduleName=${moonInputBase%.moon}
	sourceDir=`dirname "$moonInput"`

	headerInput="$sourceDir/${moduleName}C.h"
	headerOutput="$sourceDir/${moduleName}C.processed.h"
	moonOutput="${moonInput%.moon}.processed.moon"
	luaOutput="$2"

	if [[ -r $headerInput ]]; then
		# clean up excess newlines for aesthetics.
		cpp -P "$headerInput" | perl -pe "s/^\n$//g" > "$headerOutput"
		# drop the processed header into the moonscript file.
		cat "$moonInput" | perl -pe "s/___INCLUDE___/`cat "$headerOutput"`/" > "$moonOutput"
		# clean up preprocessed header
		# compile the moonscript file.
		moonc -o "$luaOutput" "$moonOutput"
		rm "$headerOutput" "$moonOutput"
	else
		moonc -o "$luaOutput" "$moonInput"
	fi

	shift 2
done
