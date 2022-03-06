#!/bin/sh

USAGE=$(cat <<-END
Creates a black outline around sprites.

OVERWRITES INPUT FILES /!.

Usage example:

    bin/outline.sh sprites/items/laec_*.png

END
)


if [ $# -eq 0 ]; then
    echo "${USAGE}"
    exit 1
fi


for image_filepath in "$@"
do
        convert \
        ${image_filepath} \
        \( \
            +clone \
            -fill White -colorize 100%% \
            -background Black -flatten \
            -morphology Dilate Disk:2 \
            -threshold 50%% \
            -alpha Copy \
            -fill Black -colorize 100%% \
        \) \
        +swap \
        -composite \
        PNG32:${image_filepath}
done

