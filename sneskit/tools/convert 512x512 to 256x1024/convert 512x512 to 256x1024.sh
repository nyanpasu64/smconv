#!/bin/sh
# convert 512x512 image to 256x1024 for snesgrit
# requires imagemagick

TMP1="very_temp_gfx_cnv_file_map001.png"
TMP2="very_temp_gfx_cnv_file_map002.png"
TMP3="very_temp_gfx_cnv_file_map003.png"
TMP4="very_temp_gfx_cnv_file_map004.png"

trap cleanup 1 2 3 6 15

cleanup() {
rm "$TMP1" "$TMP2" "$TMP3" "$TMP4"
}

if [ -f "$1" ]; then

	IMG_DIM=$( file -b "$1" | tr ',' '\n' | head -n2 | tail -n1 | sed 's/ //g' )

	if [[ $IMG_DIM == "512x512" ]]; then
		echo "Converting image to 256x1024"
		convert "$1" -crop 256x256+000+000 "$TMP1"
		convert "$1" -crop 256x256+256+000 "$TMP2"
		convert "$1" -crop 256x256+000+256 "$TMP3"
		convert "$1" -crop 256x256+256+256 "$TMP4"
		convert "$TMP1" "$TMP2" "$TMP3" "$TMP4" -append final.png
		cleanup
	else
		echo "Input image size must be 512x512, not $IMG_DIM"
	fi

else
	echo "Missing input filename."
fi
