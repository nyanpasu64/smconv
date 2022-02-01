#!/bin/bash

HELP="$0 (4|16|128|256) pcx_file_to_convert"


if [ -z "$1" ] && [ -z "$2" ]; then
	echo $HELP; exit -1;
else
	gfx2snes -m7 -m! -pc"$1" -po"$1" "$2"
fi
