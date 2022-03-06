extends "res://core/ItemsPalette.gd"

func get_color(concept_full: String, default_color:= Color.white) -> Color:
	"""
	Gets the color from this palette for the provided concept.
	
	concept_full:
		A concept with perhaps the prefix `text_`. (if applicable)
		Eg: "laec", "text_laec", "text_win", "text_lonely", …
	default_color:
		Will be used if nothing was found in this palette.
	"""
	return Color.white
