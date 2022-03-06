#!/bin/sh

# Prints something like v0.1-27-g5b8d6e4
# <most recent git tag>-<# of commits since tag>-<commit short>

git describe --tags
