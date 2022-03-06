#!/bin/sh

# Nothing to see here…
# Just a crutch on godot's addon management.

sudo mount --bind \
	~/code/godot/godot-addon-appsettings/addons/open-hexes.appsettings/ \
	addons/open-hexes.appsettings/
