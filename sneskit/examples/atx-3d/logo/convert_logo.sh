#!/bin/sh
ERR="Please provide a PNG image to convert"

# convert logo

if [ -z "$1" ]; then echo $ERR; exit -1; else

	snesgrit "$1" -gB4 -gzl -m -mz! -pe16 -ftb

	# strip high byte and print output to console

	hexdump -ve '1/1 "%.2x"' "${1%%.png*}.map.bin" | fold -w 2 | tr '\n' ' ' | fold -w 48 | awk '{ print "\t.byte\t$" $1 ",$" $3 ",$" $5 ",$" $7 ",$" $9 ",$" $11 ",$" $13 ",$" $15}'

fi
