#!/bin/bash
set -e;

# Usage: makegif.sh in out

FILTER='scale=300:-1';
rm $2 || true;

ffmpeg -i $1 -vf "$FILTER,palettegen" -y /tmp/palette.png;
ffmpeg -i $1 -i /tmp/palette.png -lavfi "$FILTER [x]; [x][1:v] paletteuse=dither=bayer" $2
