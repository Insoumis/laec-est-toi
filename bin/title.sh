#!/usr/bin/env bash

# Helper tool to make big titles as comments in the code

if [ "$#" -eq 0 ] ; then
  echo "Usage: ./title.sh My Awesome Title"
  exit 1
fi


figlet -f big -w 180 $@ \
    | sed -e 's/^/# /' \
    | sed -e 's/[ ]*$//' \
    | tee /dev/tty \
    | xclip -selection clipboard


# In case tee to /dev/tty causes issues…
# ART=$( \
#     figlet -f big $@ \
#     | sed -e 's/^/# /' \
#     | sed -e 's/[ ]*$//' \
# )
# 
# echo "$ART" | xclip -selection clipboard
# echo "$ART"
