#!/bin/bash
set -e;

FILTER='scale=300:-1';
rm $2 || true;

ffmpeg -i $1 -vf "$FILTER,palettegen" -y /tmp/palette.png;
ffmpeg -i $f -i /tmp/palette.png -lavfi "$FILTER [x]; [x][1:v] paletteuse=dither=bayer" $2
