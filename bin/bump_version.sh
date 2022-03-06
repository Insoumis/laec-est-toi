#!/bin/sh

VERSION=$(./bin/get_version.sh)
echo ${VERSION} > VERSION
