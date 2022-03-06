#!/bin/sh

# Helps creating the gettext template file.

# Install:
#     pip install babel babel-godot

pybabel extract \
	-F .babelrc \
	-k text \
	-k LineEdit/placeholder_text \
	-k tr \
	-k title \
	-k Resource/title \
	-k subtitle \
	-k excerpt \
	-k link \
	-o translations/godot-l10n.pot \
	.
