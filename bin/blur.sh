#!/bin/sh

USAGE=$(cat <<-END
Blurs sprites.

OVERWRITES INPUT FILES /!.

Usage example:

    bin/blur.sh sprites/items/laec_*.png

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
            -blur 1x1 \
        \) \
        +swap \
        -composite \
        PNG32:${image_filepath}
done

