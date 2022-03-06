tool
extends Resource
class_name ItemsPalette


#  _____ _                     _____      _      _   _
# |_   _| |                   |  __ \    | |    | | | |
#   | | | |_ ___ _ __ ___  ___| |__) |_ _| | ___| |_| |_ ___
#   | | | __/ _ \ '_ ` _ \/ __|  ___/ _` | |/ _ \ __| __/ _ \
#  _| |_| ||  __/ | | | | \__ \ |  | (_| | |  __/ |_| ||  __/
# |_____|\__\___|_| |_| |_|___/_|   \__,_|_|\___|\__|\__\___|
#
#
# Used to customize the colors of items per level.
#
# Holds a color for each (concept, is_text) pair.
# We call that pair "full" concept. Eg: "text_laec", "laec", or "text_win"…
# Hence, `text` and `not text` concepts are allowed to hold different colors.
# 
# We are using a simple Dictionary instead of Gdscript generation.
# → Found get_property_list but no setter, as well.
# → Dictionary works well enough.
# 
# You can also override this class to make a dynamic palette,
# like a palette that is all white all the time for example.
# Or a random one ?  That would be funny !
# 
# See res://palettes/ for existing palettes.
# 


# Maps "full" concepts (text_you, laec, text_laec, …) to colors.
# A "full" concept may have the prefix `text_`, if applicable.
# It's basically a hash of both concept and is_text.
# Not all colors need to be defined in your palette.
# The level will complete your palette with defaults.
export var colors := Dictionary()  # String => Color


# Fake toggles, used as uitility buttons in the editor
export var add_defaults_btn : bool setget __set_add, __dummy_get
export var remove_defaults_btn : bool setget __set_remove, __dummy_get


func __dummy_get() -> bool:
	return false


func __set_add(to_value: bool):
	if to_value:
		complete_with_defaults()


func __set_remove(to_value: bool):
	if to_value:
		remove_defaults()


func _init():
	init()  # so children can override


func init():
	"""
	Leave it be, we don't want the editor to add and save new values.
	Keep in mind this is a tool and init() will be run in editor mode as well.
	"""
	pass

func complete_with_defaults():# -> ItemsPalette:
	"""
	Fills colors of missing concepts with value from their own pixel file color.
	"""
	var has_changed := false
	for item in ItemsPool.list_items():
		if not self.colors.has(item.concept_full):
			var default_color = SpriteFramesFactory.get_color_for_concept(
				item.concept, item.is_text
			)
			self.colors[item.concept_full] = default_color
			has_changed = true
	
	if has_changed:
		#emit_changed()
		property_list_changed_notify()
	
	return self


func remove_defaults():# -> ItemsPalette:
	"""
	Removes colors of concepts that are similar to defaults.
	"""
	var has_changed := false
	for item in ItemsPool.list_items():
		if self.colors.has(item.concept_full):
			var default_color = SpriteFramesFactory.get_color_for_concept(
				item.concept, item.is_text
			)
			if self.colors[item.concept_full] == default_color:
				if self.colors.erase(item.concept_full):
					has_changed = true
	
	if has_changed:
		#emit_changed()
		property_list_changed_notify()
	
	return self


func get_color(concept_full: String, default_color:= Color.white) -> Color:
	"""
	Gets the color from this palette for the provided concept.
	
	concept_full:
		A concept with perhaps the prefix `text_`. (if applicable)
		Eg: "laec", "text_laec", "text_win", "text_lonely", …
	default_color:
		Will be used if nothing was found in this palette.
	"""
	if self.colors.has(concept_full):
		return self.colors[concept_full]
	return default_color

