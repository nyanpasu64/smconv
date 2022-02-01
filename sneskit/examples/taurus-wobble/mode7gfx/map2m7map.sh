#!/bin/sh
# remove palette data from map

HELP="$0 pcx_file_to_convert"

if [ -z "$1" ]; then

	echo $HELP; exit -1;

else

	gfx2snes -m -p! "$1"; rm -f "${1%%.pcx*}.pic"

	# also, WTF? Why does the output of hexdump differ
	# when run as a script?! -ve '1/1 "%.2x"' has been
	# added to replicate the output when run from the
	# commandline

	hexdump -ve '1/1 "%.2x"' "${1%%.pcx*}.map" | fold - -w2 | tr '\n' ' ' | fold - -w 48 | awk '{ print $1 $3 $5 $7 $9 $11 $13 $15 }' | xxd -r -p > "${1%%.pcx*}.bin" 

fi
