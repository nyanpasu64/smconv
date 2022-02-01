#!/bin/sh
###########################################################################
bar="////////////////////////////////////////////////////////"
err00="Usage:\nexhirom.sh filename [options]\n\n 6\t48mbit rom\n 8\t63mbit rom\n"
err01="ERROR:"
err02="WARNING:"
err03="not found!"
err04="Did you remember to export EXHIROM in the Makefile first"
err05="checksum will not be fixed"
lines1=264192
lines2=4096	# head
lines3=2048	# tail
tmp1=ROM1.rom
tmp2=ROM2.rom
###########################################################################
trap cleanup 1 2 3 6 15
###########################################################################
clean() {
rm -f -- "$nam" "$tmp1" "$tmp2"
}
###########################################################################
cleanup() {
echo -e "\nCaught Signal :("
clean
rm -f -- "$rom"
exit 1
}
###########################################################################

if [ -z "$1" ]; then echo -ne "$err00"; exit; fi


output="${2%%.sfc*}.rom"; input="$2"

if [ -z "$2" ]; then echo -ne "$err00"; exit; fi

case "$1" in
  1|6|48|48mbit) lines4=126976; size="ExHiROM (48mbit)"
;;
  2|8|64|64mbit) lines4=258048; size="ExHiROM (64mbit)"
;;
  special) lines4=549080 ; size="ExHiROM (96mbit)"
esac

#if [[ ! -e "$input" ]]; then echo; echo -e "$err01 $err04"; exit -1; fi

hexdump=$(which hexdump)

if [[ ! -e "$hexdump" ]]; then echo; echo -e "$err01 hexdump $err03"; clean; exit -1; fi

xxd=$(which xxd)

if [[ ! -e "$xxd" ]]; then echo; echo -e "$err01 xxd $err03"; clean; exit -1; fi

hexdump -ve '1/1 "%.2x"' < "$input" | fold - -s -w32 > "$tmp1"
echo $bar; echo $size
head -n $lines1 "$tmp1" > "$tmp2"
echo "Mirroring CROM"
head -n $lines2 "$tmp1" | tail -n $lines3 >> "$tmp2"
tail -n $lines4 "$tmp1" >> "$tmp2"

cat "$tmp2" | tr -d '\n' | xxd -r -p > "$output"

  ############                  ##
  #                              #
  ##                  ############

echo "$bar"
clean
