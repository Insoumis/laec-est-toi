tool
extends Node
#class_name ItemsPool

#  _____ _                     _____            _
# |_   _| |                   |  __ \          | |
#   | | | |_ ___ _ __ ___  ___| |__) |__   ___ | |
#   | | | __/ _ \ '_ ` _ \/ __|  ___/ _ \ / _ \| |
#  _| |_| ||  __/ | | | | \__ \ |  | (_) | (_) | |
# |_____|\__\___|_| |_| |_|___/_|   \___/ \___/|_|
#
#
# This is a Singleton now.


# When unspecified in the file name
export var default_lang := 'fr'


const ITEM_FILENAME_REGEX := \
	"(?<text>text_|)" +\
	"(?<concept>.+?)" +\
	"(?<color>_color|)" +\
	"(?<direction>" +\
	"_right|_top_right|_bottom_right|_left|_top_left|_bottom_left|)" +\
	"(?:" +\
		"(?<animation>_[0-9]+)" +\
		"(?<shiver>_[0-9]+)" +\
	"|" +\
		"(?<animation>)" +\
		"(?<shiver>_[0-9]+)" +\
	"|" +\
		"(?<animation>)" +\
		"(?<shiver>)" +\
	")" +\
	"(?<lang>[.][a-z]{2,3}|)" +\
	"[.]png"


# Lightweight Item entity.
# Took me too long to understand we needed something else than Nodes for each of our entities.
# fixme: Move to own file, rename as ItemResource, extend Resource
class PoolItem:
	extends Reference
	var is_text := true
	var concept := 'undefined'
	var concept_full : String setget ,get_concept_full
	var directions := Array()  # of Directions.XXXX available as files (maybe not useful)
	var animations := Dictionary()  # Directions.XXXX => Dictionary(animation_state => Array of filepaths)
	var filepaths := Array()
	var filepaths_relative := Array()
	
	# memoization cache
	var available_animation_mapping := Dictionary()  # Directions.XXXX => anmation_name
	
	func get_concept_full():
		return ('text_' if is_text else '') + concept

	func get_animation_prefix_for(direction) -> String:
		""" Returns full concept and direction: 'laec_top_left' for example """
		if not self.available_animation_mapping.has(direction):
			self.available_animation_mapping[direction] = find_closest_animation_prefix_for(direction)
		return self.available_animation_mapping[direction]
#		return get_closest_animation_prefix_for(direction)
#		breakpoint
#		return 'undefined'
	
	func find_closest_animation_prefix_for(direction) -> String:
		if direction == Directions.TOP_LEFT:
			if self.animations.has(Directions.TOP_LEFT):
				return "%s_%s" % [self.concept_full, Directions.as_string(Directions.TOP_LEFT)]
			elif self.animations.has(Directions.TOP_RIGHT):
				return "%s_%s" % [self.concept_full, Directions.as_string(Directions.TOP_RIGHT)]
			elif self.animations.has(Directions.LEFT):
				return "%s_%s" % [self.concept_full, Directions.as_string(Directions.LEFT)]
			elif self.animations.has(Directions.RIGHT):
				return "%s_%s" % [self.concept_full, Directions.as_string(Directions.RIGHT)]
			else:
				return self.concept_full
		elif direction == Directions.TOP_RIGHT:
			if self.animations.has(Directions.TOP_RIGHT):
				return "%s_%s" % [self.concept_full, Directions.as_string(Directions.TOP_RIGHT)]
			elif self.animations.has(Directions.TOP_LEFT):
				return "%s_%s" % [self.concept_full, Directions.as_string(Directions.TOP_LEFT)]
			elif self.animations.has(Directions.RIGHT):
				return "%s_%s" % [self.concept_full, Directions.as_string(Directions.RIGHT)]
			elif self.animations.has(Directions.LEFT):
				return "%s_%s" % [self.concept_full, Directions.as_string(Directions.LEFT)]
			else:
				return self.concept_full
		elif direction == Directions.LEFT:
			if self.animations.has(Directions.LEFT):
				return "%s_%s" % [self.concept_full, Directions.as_string(Directions.LEFT)]
			elif self.animations.has(Directions.RIGHT):
				return "%s_%s" % [self.concept_full, Directions.as_string(Directions.RIGHT)]
			else:
				return self.concept_full
		elif direction == Directions.RIGHT:
			if self.animations.has(Directions.RIGHT):
				return "%s_%s" % [self.concept_full, Directions.as_string(Directions.RIGHT)]
			elif self.animations.has(Directions.LEFT):
				return "%s_%s" % [self.concept_full, Directions.as_string(Directions.LEFT)]
			else:
				return self.concept_full
		elif direction == Directions.BOTTOM_LEFT:
			if self.animations.has(Directions.BOTTOM_LEFT):
				return "%s_%s" % [self.concept_full, Directions.as_string(Directions.BOTTOM_LEFT)]
			elif self.animations.has(Directions.BOTTOM_RIGHT):
				return "%s_%s" % [self.concept_full, Directions.as_string(Directions.BOTTOM_RIGHT)]
			elif self.animations.has(Directions.LEFT):
				return "%s_%s" % [self.concept_full, Directions.as_string(Directions.LEFT)]
			elif self.animations.has(Directions.RIGHT):
				return "%s_%s" % [self.concept_full, Directions.as_string(Directions.RIGHT)]
			else:
				return self.concept_full
		elif direction == Directions.BOTTOM_RIGHT:
			if self.animations.has(Directions.BOTTOM_RIGHT):
				return "%s_%s" % [self.concept_full, Directions.as_string(Directions.BOTTOM_RIGHT)]
			elif self.animations.has(Directions.BOTTOM_LEFT):
				return "%s_%s" % [self.concept_full, Directions.as_string(Directions.BOTTOM_LEFT)]
			elif self.animations.has(Directions.RIGHT):
				return "%s_%s" % [self.concept_full, Directions.as_string(Directions.RIGHT)]
			elif self.animations.has(Directions.LEFT):
				return "%s_%s" % [self.concept_full, Directions.as_string(Directions.LEFT)]
			else:
				return self.concept_full
		else:
			return self.concept_full


# Inefficient, we'll optimize when we'll have banchmark metrics
class ItemsSorter:
	# true if a < b else false
	static func sort_items(item_a: PoolItem, item_b: PoolItem) -> bool:
		if not item_a:
			return true
		if not item_b:
			return false
		if item_a.concept == item_b.concept:
			if item_a.is_text:
				if item_b.is_text:
					return false
				else:
					return false
			if item_b.is_text:
				if item_a.is_text:
					return false
				else:
					return true
			return false
		return sort_concepts(item_a.concept, item_b.concept)

	# true if a < b else false
	static func sort_concepts(concept_a: String, concept_b: String) -> bool:
		var lexicographical : bool = concept_a.casecmp_to(concept_b) == -1
		
		if Words.is_operator(concept_a):
			if Words.is_operator(concept_b):
				return lexicographical
			else:
				return true
		
		if Words.is_operator(concept_b):
			if Words.is_operator(concept_a):
				return lexicographical
			else:
				return false
		
		if Words.is_verb(concept_a):
			if Words.is_verb(concept_b):
				return lexicographical
			else:
				return true
		
		if Words.is_verb(concept_b):
			if Words.is_verb(concept_a):
				return lexicographical
			else:
				return false
		
		if Words.is_preposition(concept_a):
			if Words.is_preposition(concept_b):
				return lexicographical
			else:
				return true
		
		if Words.is_preposition(concept_b):
			if Words.is_preposition(concept_a):
				return lexicographical
			else:
				return false
		
		if Words.is_epithet_prefix(concept_a):
			if Words.is_epithet_prefix(concept_b):
				return lexicographical
			else:
				return true
		
		if Words.is_epithet_prefix(concept_b):
			if Words.is_epithet_prefix(concept_a):
				return lexicographical
			else:
				return false
		
		if Words.is_quality(concept_a):
			if Words.is_quality(concept_b):
				return lexicographical
			else:
				return true
		
		if Words.is_quality(concept_b):
			if Words.is_quality(concept_a):
				return lexicographical
			else:
				return false
		
		if Words.is_synth(concept_a):
			if Words.is_synth(concept_b):
				return lexicographical
			else:
				return true
		
		if Words.is_synth(concept_b):
			if Words.is_synth(concept_a):
				return lexicographical
			else:
				return false
		
#		if Words.is_noun(concept_a):
#			if Words.is_noun(concept_b):
#				return lexicographical
#			else:
#				return true
#
#		if Words.is_noun(concept_b):
#			if Words.is_noun(concept_a):
#				return lexicographical
#			else:
#				return false
		
		return lexicographical


var items := Array()  # sorted alphabetically (by filename, so text_ prefix counts)
var items_sorted_for_editor := Array()

var items_by_concept: Dictionary


# We need to be available before we are _ready
#func _ready():
func _init():
	recollect_items()


func recollect_items():
	self.items.clear()
	self.items = list_items()
	self.items_sorted_for_editor.clear()
	self.items_sorted_for_editor = self.items.duplicate(false)
	self.items_sorted_for_editor = list_items_sorted(self.items_sorted_for_editor)
	
	#write_animation_mapping()
	reindex_items()
#	for item in items:
#		print(item.concept_full)
#		print(item.available_animation_mapping)


func get_items():
	return self.items


func get_items_sorted_for_editor():
	return self.items_sorted_for_editor


func get_item_by_concept_full(concept_full: String) -> PoolItem:
	if self.items_by_concept.has(concept_full):
		return self.items_by_concept[concept_full]
	if concept_full.begins_with('text'):
		return self.items_by_concept['text_undefined']
	return self.items_by_concept['undefined']


#func write_animation_mapping():
#	for item in self.items:
#		item.available_animation_mapping = Dictionary()
#		item.available_animation_mapping["top_left"] = get_closest_animation_for(Directions.TOP_LEFT, item)
#		item.available_animation_mapping["top_right"] = get_closest_animation_for(Directions.TOP_RIGHT, item)
#		item.available_animation_mapping["left"] = get_closest_animation_for(Directions.LEFT, item)
#		item.available_animation_mapping["right"] = get_closest_animation_for(Directions.RIGHT, item)
#		item.available_animation_mapping["bottom_left"] = get_closest_animation_for(Directions.BOTTOM_LEFT, item)
#		item.available_animation_mapping["bottom_right"] = get_closest_animation_for(Directions.BOTTOM_RIGHT, item)
	# ?
#	return items.duplicate()


func reindex_items():
	self.items_by_concept = Dictionary()
	for item in self.items:
		self.items_by_concept[item.concept_full] = item


static func list_items_sorted(io_items := []) -> Array:  # PoolItem[]
	if not io_items:
		io_items = list_items()
	io_items.sort_custom(ItemsSorter, "sort_items")
	return io_items


static func list_items() -> Array:  # PoolItem[]
	var listed_items := Array()
	
	# TODO: allow user-defined items
	# We want the union of multiple paths, later overrides former.
	var where := "res://sprites/items"
	
	# When specified, should prefer l10ned files (todo)
	var _preferred_lang := ''
	
	var regex := RegEx.new()
	var regex_err = regex.compile(where + "/" + ITEM_FILENAME_REGEX + "$")
	if regex_err != OK:
		printerr("ItemsPool failed to compile the regex in list_items()")
		return listed_items
	var finder := FinderClass.new()  # uses finder.cfg cache on exported builds
	var found = finder.list_directory(where)
	var found_filepaths : Array = found['files']
	found_filepaths.sort()
	for filepath in found_filepaths:
		var matches: RegExMatch = regex.search(filepath)
		if matches:
			var filepath_relative: String = filepath.replace(where, "").substr(1)
			var concept: String = matches.strings[matches.names['concept']]
			
			var text: String = matches.strings[matches.names['text']]
			var is_text = text == 'text_'
			
			var is_color = matches.strings[matches.names['color']] == "_color"
			if is_color:
				continue  # skip color-defining files
			
			var direction_string: String = matches.strings[matches.names['direction']]
			var direction  # Directions.XXXX
			var has_direction := false
			if direction_string:
				direction = Directions.from_string(direction_string.substr(1))
				has_direction = true
			
			var animation_string: String = matches.strings[matches.names['animation']]
			var animation := 0
			var _has_animation := false  # perhaps useful later
			if animation_string:
				animation = int(animation_string.substr(1))
				_has_animation = true
			
			var shiver_string: String = matches.strings[matches.names['shiver']]
			var _shiver := 0  # perhaps useful later
			var _has_shiver := false  # perhaps useful later
			if shiver_string:
				_shiver = int(shiver_string)
				_has_shiver = true
			
			var _has_lang := false
			var _lang := 'fr'
			var lang_string: String = matches.strings[matches.names['lang']]
			if lang_string:
				_has_lang = true
				continue  # skip for now, handle l10n fallback later
			
			var existing_item: PoolItem
			for unique in listed_items:
				if unique.concept == concept and unique.is_text == is_text:
					existing_item = unique
					break
			
			var item
			if not existing_item:
				item = PoolItem.new()
				item.concept = concept
				item.is_text = is_text
				listed_items.append(item)
			else:
				item = existing_item
			
			item.filepaths_relative.append(filepath_relative)
			item.filepaths.append(filepath)
			
			if has_direction:
				if not item.directions.has(direction):
					item.directions.append(direction)
			
#			if has_animation:
			var animation_direction = Directions.NONE
			if has_direction:
				animation_direction = direction
			if not item.animations.has(animation_direction):
				item.animations[animation_direction] = Dictionary()
			if not item.animations[animation_direction].has(animation):
				item.animations[animation_direction][animation] = Array()
			item.animations[animation_direction][animation].append(filepath)
	
	finder.free()
	return listed_items


#static func get_closest_animation_for(direction, item):
#	if direction == Directions.TOP_LEFT:
#		if item.animations.has(Directions.TOP_LEFT):
#			return item.concept_full + "_top_left"
#		elif item.animations.has(Directions.TOP_RIGHT):
#			return item.concept_full + "_top_right"
#		elif item.animations.has(Directions.LEFT):
#			return item.concept_full + "_left"
#		elif item.animations.has(Directions.RIGHT):
#			return item.concept_full + "_right"
#		else:
#			return item.concept_full
#	elif direction == Directions.TOP_RIGHT:
#		if item.animations.has(Directions.TOP_RIGHT):
#			return item.concept_full + "_top_right"
#		elif item.animations.has(Directions.TOP_LEFT):
#			return item.concept_full + "_top_left"
#		elif item.animations.has(Directions.RIGHT):
#			return item.concept_full + "_right"
#		elif item.animations.has(Directions.LEFT):
#			return item.concept_full + "_left"
#		else:
#			return item.concept_full
#	elif direction == Directions.LEFT:
#		if item.animations.has(Directions.LEFT):
#			return item.concept_full + "_left"
#		elif item.animations.has(Directions.RIGHT):
#			return item.concept_full + "_right"
#		else:
#			return item.concept_full
#	elif direction == Directions.RIGHT:
#		if item.animations.has(Directions.RIGHT):
#			return item.concept_full + "_right"
#		elif item.animations.has(Directions.LEFT):
#			return item.concept_full + "_left"
#		else:
#			return item.concept_full
#	elif direction == Directions.BOTTOM_LEFT:
#		if item.animations.has(Directions.BOTTOM_LEFT):
#			return item.concept_full + "_bottom_left"
#		elif item.animations.has(Directions.BOTTOM_RIGHT):
#			return item.concept_full + "_bottom_right"
#		elif item.animations.has(Directions.LEFT):
#			return item.concept_full + "_left"
#		elif item.animations.has(Directions.RIGHT):
#			return item.concept_full + "_right"
#		else:
#			return item.concept_full
#	elif direction == Directions.BOTTOM_RIGHT:
#		if item.animations.has(Directions.BOTTOM_RIGHT):
#			return item.concept_full + "_bottom_right"
#		elif item.animations.has(Directions.BOTTOM_LEFT):
#			return item.concept_full + "_bottom_left"
#		elif item.animations.has(Directions.RIGHT):
#			return item.concept_full + "_right"
#		elif item.animations.has(Directions.LEFT):
#			return item.concept_full + "_left"
#		else:
#			return item.concept_full


static func parse_name(file_name: String, path: String):
	#breakpoint deprecated
	if file_name.ends_with("_0.png"):
		var regex := RegEx.new()
		var _careful = regex.compile(
			"(?<is_text>text_)?" +
			"(?<item_name>[A-Za-z0-9-]+)?_?" +
			
			"(?<direction>(bottom_left|bottom_right|left|right|top_left|top_right))?_?" +
			"(?<animation>[0-9]+)?_?" +
			"(?<frisson>[0-9]+)?_?" +
			
			"[.]png$"
		)
		var result = regex.search(file_name)
		
		if result:
			var item := Dictionary()
			item["file_name"] = file_name
			item["file_path"] = path + file_name
			item["concept"] = result.get_string("item_name")
			if result.get_string("direction") != "":
				item["direction"] = result.get_string("direction")
			else:
				item["direction"] = null
			item["is_text"] = result.get_string("is_text") == "text_"
			if result.get_string("animation") != "":
				item["animation"] = result.get_string("animation")
			else:
				item["animation"] = null
			if result.get_string("frisson") != "":
				item["frisson"] = result.get_string("frisson")
			else:
				item["frisson"] = null
			return item

var SpritesList
#const SPRITE_PATH = "res://sprites/items"
#

# Deprecated, but still used by ItemWizard
static func get_items_from_sprites_dir(path):
	#breakpoint # deprecated !
	var dir = Directory.new()
	var results = Array()
	var finder := FinderClass.new()  # uses finder.cfg cache on exported builds
#	var where = SPRITE_PATH
	var found = finder.list_directory(path)
	var found_filepaths : Array = found['files']
	for sprite_path in found_filepaths:
		if sprite_path.ends_with("0.png"):
			var file_name = sprite_path.replace(path, "")
			file_name = file_name.replace("/", "")
#			print("file name: ", file_name)
			var item = parse_name(file_name, path)
			if item:
				results.push_back(item)
	#					print(item)
			file_name = dir.get_next()

	return results

