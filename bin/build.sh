#!/usr/bin/env bash

# Build distributables of a game made with Godot.
# Execute this from project root.
# Overwrites existing files.
# Will create a directory with this build name, and package it.
# sudo apt install fortunes cowsay

# The only reason we're not exporting to 32 bits is that 2038 is getting close.
# It could also be laziness. No one knows. Enable 32bits if you need them!

# More exporting options are available.
# See https://github.com/godotengine/godot/blob/5ae78fd/main/main.cpp#L108

# INTERNAL CONFIG #############################################################

# Game name (mandatory) and author (for itch)
GAME_NAME=${GAME_NAME:-"laec-est-vous"}
GAME_AUTHOR=${GAME_AUTHOR:-"discord-insoumis"}

# Godot executable (make sure it's 3.x)
GODOT=${GODOT:-"godot"}
# Relative to project root, or absolute
BUILD_ROOT_PATH="build"
# Delete the produced intermediary files, so that we can rsync the whole dir.
# HTML5 build will disable this by default.
DELETE_INTERMEDIARY=1
# You'll need fortune and cowsay
COW_EYES="o~"
# Say yes to all prompts? (bound to the -y CLI option)
YES=0
# Upload to itch?
SHOULD_UPLOAD=0


# COLORS ######################################################################

Off='\033[0m'             # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# Underline
UBlack='\033[4;30m'       # Black
URed='\033[4;31m'         # Red
UGreen='\033[4;32m'       # Green
UYellow='\033[4;33m'      # Yellow
UBlue='\033[4;34m'        # Blue
UPurple='\033[4;35m'      # Purple
UCyan='\033[4;36m'        # Cyan
UWhite='\033[4;37m'       # White

# Background
On_Black='\033[40m'       # Black
On_Red='\033[41m'         # Red
On_Green='\033[42m'       # Green
On_Yellow='\033[43m'      # Yellow
On_Blue='\033[44m'        # Blue
On_Purple='\033[45m'      # Purple
On_Cyan='\033[46m'        # Cyan
On_White='\033[47m'       # White


# INPUT #######################################################################

while (($# > 0))
  do
  case $1 in
      "-y")
          YES=1 ; shift ;;
      "-u")
          SHOULD_UPLOAD=1 ; shift ;;
      *)
          BUILD_TARGET=$1 ; shift ;;
  esac
done

if [ -z "${BUILD_TARGET}" ] ; then
    BUILD_TARGET="all"
fi


###############################################################################


# Compression algorithm used for packaging
BUILD_COMPRESSION=""
# We have to provide a file extension to the BINARY_NAME,
# until Godot is patched, or the .pck will be wrongly named.
BINARY_NAME=""
# The name of the corresponding export preset in export_presets.cfg
EXPORT_PRESET=""

case ${BUILD_TARGET} in
"all")
    BUILD_SCRIPT="bash bin/build.sh"
    YES_OPTION=""
    if [ ${YES} -eq 1 ]; then YES_OPTION="-y"; fi
    UPLOAD_OPTION=""
    if [ ${SHOULD_UPLOAD} -eq 1 ]; then UPLOAD_OPTION="-u"; fi
    #${BUILD_SCRIPT} ${YES_OPTION} ${UPLOAD_OPTION} linux32
    ${BUILD_SCRIPT} ${YES_OPTION} ${UPLOAD_OPTION} linux64
    #${BUILD_SCRIPT} ${YES_OPTION} ${UPLOAD_OPTION} win32
    ${BUILD_SCRIPT} ${YES_OPTION} ${UPLOAD_OPTION} win64
    ${BUILD_SCRIPT} ${YES_OPTION} ${UPLOAD_OPTION} html5
    ${BUILD_SCRIPT} ${YES_OPTION} ${UPLOAD_OPTION} mac64
    #${BUILD_SCRIPT} ${YES_OPTION} ${UPLOAD_OPTION} source
    exit 0
    ;;
"linux64")
    EXPORT_PRESET="Linux/X11"
    BINARY_NAME="${GAME_NAME}.x64"
#    BUILD_COMPRESSION="7z"
    # We'd love
    BUILD_COMPRESSION="tarball"
    ;;
"linux32")
    EXPORT_PRESET="Linux/X11 32"
    BINARY_NAME="${GAME_NAME}.x86"
    BUILD_COMPRESSION="tarball"
    ;;
"win64")
    EXPORT_PRESET="Windows Desktop"
    BINARY_NAME="${GAME_NAME}.exe"
    BUILD_COMPRESSION="zip"
    ;;
"win32")
    EXPORT_PRESET="Windows Desktop 32"
    BINARY_NAME="${GAME_NAME}.exe"
    BUILD_COMPRESSION="zip"
    ;;
"mac64")
    EXPORT_PRESET="Mac OSX"
    BINARY_NAME="${GAME_NAME}.zip"
    BUILD_COMPRESSION="zip"
    ;;
"html5")
    EXPORT_PRESET="HTML5"
    BINARY_NAME="${GAME_NAME}.html"
    BINARY_NAME="index.html"
    BUILD_COMPRESSION="none"
    DELETE_INTERMEDIARY=0
    ;;
"source")
    EXPORT_PRESET=""
    BINARY_NAME=""
    BUILD_COMPRESSION="7z"
    DELETE_INTERMEDIARY=1
    ;;
*)
    echo -e "${BWhite}${On_Red}WRONG BUILD TARGET${Off}"
    echo -e "Available build targets:"
    echo -e "  linux32, linux64, win32, win64, html5"
    echo -e "Usage example:"
    echo -e "  $ bash bin/build.sh linux64"
    exit 1
    ;;
esac


BUILD_PARENT_PATH="${BUILD_ROOT_PATH}/${BUILD_TARGET}"
VERSION=${VERSION:-`bash bin/get_version.sh`}
VERSION_NO_DOT=$(echo ${VERSION} | sed -E 's/[.]/-/g')
BUILD_NAME="${GAME_NAME}_${VERSION_NO_DOT}_${BUILD_TARGET}"

BUILD_PATH="${BUILD_PARENT_PATH}/${BUILD_NAME}"


# MASTHEAD ####################################################################

echo -e "  ${BWhite}${On_Purple}                            ${Off}"
echo -e " ${BWhite}${On_Purple}   GODOT BUILDER INSOUMIS    ${Off}"
echo -e "  ${BWhite}${On_Purple}                            ${Off}"
echo -e "  Build arch: ${BUILD_TARGET}"
echo -e "  Build name: ${BUILD_NAME}"
echo -e "  Build path: ${BUILD_PATH}"
echo -e "  Export preset: ${EXPORT_PRESET}"


# SANITY CHECKS ###############################################################

# Assert that the parent build directory exists
if [ ! -d ${BUILD_PARENT_PATH} ]; then
    echo -e "${BWhite}${On_Red}Build parent path '${BUILD_PARENT_PATH}' does not exist or is unreadable.${Off}"

    if [ ${YES} -eq 1 ]; then
        SHOULD_CREATE="Y"
    else
        read -r -p "Try to create it? [Y/n] " SHOULD_CREATE
    fi
    case "$SHOULD_CREATE" in
        [nN][oO]|[nN])
            echo -e "Very well."
            echo -e "…"
            echo -e "…"
            echo -e "…"
            echo -e "I'm kinda hurt ; I just wanted to help!"
            echo -e "Goodbye, then!"
            exit 1
            ;;
        [yY][eE][sS]|[yY]|*)
            mkdir --parents ${BUILD_PARENT_PATH}
            MKDIR_RET=$?
            if [ ${MKDIR_RET} != 0 ]; then
                echo -e "Could not create the directory."
                echo -e "…"
                echo -e "Sorry."
                echo -e "…"
                echo -e "Probably a permissions issue."
                echo -e "Exiting…"
                exit 1
            fi
            echo -e "Created the directory ${Yellow}${BUILD_PARENT_PATH}${Off}."
            ;;
    esac
fi


# INITIAL CLEANUP #############################################################

echo -e "${Green}Preparing local files…${Off}"

# Write to VERSION file
echo ${VERSION} > VERSION

# Remove the build directory if it already exists
if [ -d ${BUILD_PATH} ]; then
    echo -e "${Red}Found existing dir at build path ${Yellow}${BUILD_PATH}${Red}.${Off}"
    if [ ${YES} -eq 1 ]; then
        SHOULD_REMOVE="Y"
    else
        read -r -p "Try to remove it? [Y/n] " SHOULD_REMOVE
    fi
    case "$SHOULD_REMOVE" in
        [nN][oO]|[nN])
            echo -e "You're right."
            echo -e "Best be cautious about this sort of thing."
            echo -e "…"
            echo -e "See you later!"
            exit 1
            ;;
        [yY][eE][sS]|[yY]|*)
            # DANGER ZOOOOOOONE
            rm -r ${BUILD_PATH}
            echo -e "Removed the directory ${Yellow}${BUILD_PATH}${Off}."
            ;;
    esac
fi

echo -e "${Green}Creating the build directory ${Yellow}${BUILD_PATH}${Green}…${Off}"
mkdir ${BUILD_PATH}


# ACTUAL BUILD ################################################################

# Create the game binary and .pck and other needed files.

if [ "${BUILD_TARGET}" != "source" ]; then
    
    echo -e "${Green}Building…${Off}"
    ${GODOT} --export "${EXPORT_PRESET}" ${BUILD_PATH}/${BINARY_NAME}
    
    # Ideally we have none, but it's pretty hard.
    # We need a CI that checks the output of Godot.
    echo -e "${Green}Do not panic about the errors above…${Off}"

#    if [ "${BUILD_TARGET}" = "linux64" ]; then
#        echo -e "${Green}Packing the linux binary to reduce its size…${Off}"
#        upx -9 -v ${BUILD_PATH}/${BINARY_NAME}
#    fi

fi

# Clone the source of the game

if [ "${BUILD_TARGET}" = "source" ]; then
    git clone https://framagit.org/laec-is-you/laec-is-you.git ${BUILD_PATH}
fi

#echo -e "${Green}Creating the save directory…${Off}"
#mkdir ${BUILD_PATH}/save

#echo -e "${Green}Creating the config directory…${Off}"
#mkdir ${BUILD_PATH}/config

#echo -e "${Green}Copying the default config…${Off}"
#cp config/settings.ini ${BUILD_PATH}/config/settings.ini

if [ "${BUILD_TARGET}" != "mac64" ]; then  # Trying to clean up the mac zip, see what happens
    echo -e "${Green}Copying the distributed READMEs…${Off}"
    cp dist/README-* ${BUILD_PATH}/
fi

#%SystemRoot%\explorer.exe "c:\Yaya\yoyo\"

if [[ "${BUILD_TARGET}" =~ ^(linux)(32|64)$ ]]; then
    cp dist/linux/* ${BUILD_PATH}/
fi

if [[ "${BUILD_TARGET}" =~ ^win(32|64)$ ]]; then
    cp dist/windows/* ${BUILD_PATH}/
fi


# PACKAGING ###################################################################

echo -e "${Green}Creating an archive…${Off}"

# Change directories so we have a short dir structure inside the tarball
WD=`pwd`
cd ${BUILD_PARENT_PATH}

EXTENSION=""
case ${BUILD_COMPRESSION} in
"tarball")
    EXTENSION=".tar.gz"
    tar -czvf ${BUILD_NAME}${EXTENSION} ${BUILD_NAME}
    ;;
"7z")
    EXTENSION=".7z"
    7z a ${BUILD_NAME}${EXTENSION} ${BUILD_NAME}
    ;;
"zip")
    EXTENSION=".zip"
    zip -r ${BUILD_NAME}${EXTENSION} ${BUILD_NAME}
    ;;
"none")
    # nothing is cool
    ;;
*)
    echo -e "${BWhite}${On_Red}Unknown build compression ${BUILD_COMPRESSION}.${Off}"
esac

# Revert to previous working directory
cd ${WD}


# FINAL CLEANUP ###############################################################

if [ ${DELETE_INTERMEDIARY} -eq 1 ]; then
    if [ ${BUILD_COMPRESSION} != "none" ]; then
        echo -e "${Green}Cleaning intermediary files…${Off}"
        rm -R ${BUILD_PATH}
    fi
fi



# UPLOAD ######################################################################

DOWNLOAD_FILEPATH="${BUILD_PARENT_PATH}/${BUILD_NAME}${EXTENSION}"
DIST_PATH="${BUILD_PARENT_PATH}/${BUILD_NAME}_dist"

if [ -d "${DIST_PATH}" ]; then
    rm -R "$DIST_PATH"
fi
mkdir "$DIST_PATH"

cp "${DOWNLOAD_FILEPATH}" "${DIST_PATH}/"

if [ ${SHOULD_UPLOAD} -eq 1 ] ; then
    #echo "DOWNLOAD_FILEPATH"
    echo -e "Pushing $DOWNLOAD_FILEPATH to itch…"

    if [ ${BUILD_COMPRESSION} != "none" ]; then
        if [ "${BUILD_TARGET}" = "linux64" ]; then
            # We try to trick itch into leaving our file alone, and not produce a zip by itself of it.
            # We want a tarball !
            butler push $DIST_PATH ${GAME_AUTHOR}/${GAME_NAME}:${BUILD_TARGET} --userversion ${VERSION}
        else
            butler push $DOWNLOAD_FILEPATH ${GAME_AUTHOR}/${GAME_NAME}:${BUILD_TARGET} --userversion ${VERSION}
        fi
    else
        butler push $DOWNLOAD_FILEPATH ${GAME_AUTHOR}/${GAME_NAME}:${BUILD_TARGET} --userversion ${VERSION}
    fi
fi

rm -R "$DIST_PATH"


# GOODBYE #####################################################################

echo -e "${BGreen}All done !${Off}"
echo -e "Your build is available at ${Yellow}${BUILD_PATH}${EXTENSION}${Off}."

fortune -a -n 256 | cowthink -W 79 -e ${COW_EYES}
