extends "res://menus/Intro.gd"

# __          __  _
# \ \        / / | |
#  \ \  /\  / /__| | ___ ___  _ __ ___   ___
#   \ \/  \/ / _ \ |/ __/ _ \| '_ ` _ \ / _ \
#    \  /\  /  __/ | (_| (_) | | | | | |  __/
#     \/  \/ \___|_|\___\___/|_| |_| |_|\___|
#
#
# You clicked on the little scroll, didn't you?
# 
# This is the GdScript code behind the Publisher Intro.
# … Not very interesting.
#
# Meaningful code can be found in the files in 
# - `core/`
# - `addons/laec-is-you`
# Open them from the Filesystem dock in the bottom left of the screen.
# 
# Levels are in `levels/`.
# Bug reports and specs are in `features/`.
# 
# Protip: Use CTRL+MAJ+O and type "level" to browse all level scenes.
# Protip: Use CTRL+MAJ+O and type "FeaturesRunner", and run the scene ;)


func ready():
	.ready()


func _on_StartupTimer_timeout():
	$AnimationPlayer.play("FadeIn")
