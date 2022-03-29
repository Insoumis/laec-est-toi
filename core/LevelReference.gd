extends Resource
class_name LevelReference
#class_name LevelResource  # todo #jambalai

# Kind of like a pointer to a Level.
# Does not hold all the level data, but should hold enough to invoke it.
# Also holds (if hydrated) some copied data from the level, such as title and portals.
# Semantics: it's perhaps the Level, and the current Level is LevelScene.
# Or perhaps this is a LevelSeed ?

# Headers for each base
const PHIU_HEADER_16 := "1F8B08"
const PHIU_HEADER_64 := "LisU"
const PHIU_HEADER_256 := "φ=U"
const PHIU_HEADER_1024 := "φ⇆∪"

const Jsonify = preload("res://lib/jsonify.gd")
const CompressorSerializer = preload("res://lib/CompressorSerializer.gd")


# Filepath of the scene (.tscn), or the phiu (.phiu), or the .png
# May not be set if this resource was loaded directly via string.
export var level_filepath: String

# Copies of some of the contents of the level
# These are expensive to hydrate, since we need to instantiate the level.
# Do not assume they are set.   See hydrate_from_instance()
export var title: String
export var is_in_score: bool
# Ok so long PortalResource does not refrence this class (save l∞ps)
export var portals: Array  # of PortalResource

export var parents_filepaths: Array  # of String

# NO !   save l∞ps !
#export var parents: Array  # of LevelResource (self)
#export var children: Array  # of LevelResource (self) TODO?

var is_orphan: bool setget set_is_orphan, get_is_orphan

# Both of these should be lazy methods (accessors).
# It's probably OK if they memoize.
var packed: PackedScene  # packed scene, if filepath is a `.tscn`
var pickle: Dictionary  # pickled level, if filepath is a `.phiu` or null


func set_is_orphan(_value):
	assert("READ ONLY.  Use `parents' property instead.")

func get_is_orphan():
	return self.parents_filepaths.empty()


#func hydrate_from_instance() -> int:
#	return OK

func _to_string() -> String:
	return self.level_filepath


func instantiate_scene():
	var file = File.new()
	if not file.file_exists(self.level_filepath):
#	if not Finder.exists(self.level_filepath):  # prbly an acceptable shortcut
#	if not ResourceLoader.exists(self.level_filepath):  # false fails in user://
		printerr("LevelResource.instantiate_scene() cannot find level `%s'." % self.level_filepath)
		breakpoint  # Q: what happened?   A: …
		return null
	
	if self.level_filepath.ends_with('tscn'):
		var level_scene_packed = ResourceLoader.load(self.level_filepath)
		if not level_scene_packed.can_instance():
			printerr("Level `%s' appears empty." % [self.level_filepath])
			breakpoint  # Q: what happened?   A: …
			return null
		var level_scene = level_scene_packed.instance()
		var LevelScene = load("res://addons/laec-is-you/entity/Level.gd")
		if not (level_scene is LevelScene):
			printerr("Scene `%s' is not a Level." % [self.level_filepath])
			breakpoint  # Q: what happened?   A: …
			return null
		return level_scene
	
	elif self.level_filepath.ends_with('phiu'):
		var loaded = load_from_filepath(self.level_filepath)
		if loaded != OK:
			printerr("Level `%s' could not be loaded as phiu." % [self.level_filepath])
			return null
		var level_scene_packed = load("res://core/Level.tscn")
		if not level_scene_packed.can_instance():
			printerr("Level `%s' appears empty." % [self.level_filepath])
			return null
		
		var level_scene = level_scene_packed.instance()
		level_scene.load_from_pickle(self.pickle)
		return level_scene
	
	elif self.level_filepath.ends_with('png'):
		# todo: support other formats
		pass
	
	#breakpoint
	return null




func load_from_filepath(that_filepath: String) -> int:
	if that_filepath.ends_with('phiu'):
		var file = File.new()
		var open_err = file.open(that_filepath, File.READ)
		if open_err:
			Logger.warn(
				"Cannot open PHIU file `%s'." % that_filepath, null, open_err
			)
			breakpoint
			return ERR_FILE_CANT_OPEN
		var parse_err = parse_phiu(file.get_as_text())
		file.close()
		if parse_err:
			Logger.warn(
				"Cannot parse PHIU file `%s'." % that_filepath, null, parse_err
			)
			breakpoint
			return ERR_FILE_CANT_READ

	elif that_filepath.ends_with('tscn'):
		pass
		breakpoint # todo

	elif that_filepath.ends_with('json'):
		var file = File.new()
		var open_err = file.open(that_filepath, File.READ)
		if open_err:
			Logger.warn(
				"Cannot open JSON file `%s'." % that_filepath, null, open_err
			)
			breakpoint
			return ERR_FILE_CANT_OPEN
		var parse_err = parse_phiu(file.get_as_text())
		file.close()
		if parse_err:
			Logger.warn(
				"Cannot parse JSON file `%s'." % that_filepath, null, parse_err
			)
			breakpoint
			return ERR_FILE_CANT_READ

	elif that_filepath.ends_with('png'):
		var image = Image.new()

		var load_err = image.load(that_filepath)
		if OK != load_err:
			Logger.warn("Cannot open PNG file `%s'." % that_filepath, null, load_err)
			breakpoint
			return ERR_FILE_CANT_OPEN
		var parse_err = parse_image_level(image)

		if OK != parse_err:
			Logger.warn("Cannot parse PNG file `%s'." % that_filepath, null, parse_err)
			breakpoint
			return ERR_FILE_CANT_READ

	else:
		breakpoint
		return ERR_INVALID_PARAMETER

	self.level_filepath = that_filepath
	return OK


func parse_image_level(image: Image) -> int:
	var level_and_timestamp_and_error = CompressorSerializer.decompress_string_in_image(image)

	var date = OS.get_datetime_from_unix_time(level_and_timestamp_and_error[1])
	var str_date : String = "%d/%02d/%02d at %02d:%02d" \
		% [date.year, date.month, date.day, date.hour, date.minute]

	if level_and_timestamp_and_error[2]:
		return level_and_timestamp_and_error[2]

	var json_result := JSON.parse(level_and_timestamp_and_error[0])
	if OK != json_result.error:
		printerr("Failed to parse json encoded in image data.")
		return ERR_INVALID_DATA

	var parsed_pickle = Jsonify.godotify(json_result.result)

	if parsed_pickle:
		self.pickle = parsed_pickle
		print("Extracted level from image - it was generated on %s." % str_date)

		return OK

	return ERR_INVALID_DATA


#	func parse_level_string(phiu: String):
func parse_phiu(level_string: String) -> int:
	level_string = level_string.strip_edges()
	if level_string.begins_with(PHIU_HEADER_1024):
		level_string = CompressorSerializer.decompress_string_1024(
			level_string
		)
	elif level_string.begins_with(PHIU_HEADER_256):
		level_string = CompressorSerializer.decompress_string_256(
			level_string
		)
	elif level_string.begins_with(PHIU_HEADER_64):
		level_string = CompressorSerializer.decompress_string_64(
			level_string
		)
	elif level_string.begins_with(PHIU_HEADER_16):
		level_string = CompressorSerializer.decompress_string_16(
			level_string
		)
	var jsonResult := JSON.parse(level_string)
	if OK != jsonResult.error:
		printerr("Failed to parse PHIU content.")
		return ERR_INVALID_DATA
	var parsed_pickle = Jsonify.godotify(jsonResult.result)
	
	if parsed_pickle:
		self.pickle = parsed_pickle
		return OK
	
	return ERR_INVALID_DATA


static func looks_like_phiu(some_string: String) -> bool:
	some_string = some_string.strip_edges()
	if some_string.begins_with(PHIU_HEADER_1024):
		return true
	if some_string.begins_with(PHIU_HEADER_256):
		return true
	if some_string.begins_with(PHIU_HEADER_64):
		return true
	if some_string.begins_with(PHIU_HEADER_16):
		return true
	if some_string.begins_with("{") and some_string.ends_with("}"):
		return true
	return false
