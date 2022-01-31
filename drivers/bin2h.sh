#!/bin/sh
ext=obj
output="${1%%.$ext*}.h"

if [[ -e "$1" ]]; then
	echo "output file will be: $output"

	echo "const unsigned char spc_$2_program[] = {" > "$output"

	hexdump -ve '1/1 "%.2x"' "$1" | fold - -w 2 | awk ' { print "0x" $1 } ' | tr '\n' ',' | fold - -w 80 | sed -e 's/^/\t/g;$s/.$//'>> "$output"

	echo -e "\n};" >> "$output"
	exit 0
else
	echo "Must have a .obj file and that file should exist."
	echo "$1 <- does this file exist?"
	exit 1
fi
