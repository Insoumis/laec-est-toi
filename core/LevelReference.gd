extends Reference
class_name LevelReference

# Kind of like a pointer to a Level.
# Semantics: it's perhaps the Level, and the current Level is LevelScene.
# Or perhaps this is a LevelSeed ?

# Headers for each base
const PHIU_HEADER_16 := "1F8B08"
const PHIU_HEADER_64 := "LisU"
const PHIU_HEADER_256 := "φ=U"
const PHIU_HEADER_1024 := "φ⇆∪"

const Jsonify = preload("res://lib/jsonify.gd")
const CompressorSerializer = preload("res://lib/CompressorSerializer.gd")


var filepath: String  # of the scene (.tscn) or the phiu (.phiu)
var packed: PackedScene  # packed scene, if filepath is a `.tscn`
var pickle: Dictionary  # pickled level, if filepath is a `.phiu` or null


func load_from_filepath(level_filepath: String) -> int:
	if level_filepath.ends_with('phiu'):
		var file = File.new()
		var open_err = file.open(level_filepath, File.READ)
		if open_err:
			Logger.warn(
				"Cannot open PHIU file `%s'." % level_filepath, null, open_err
			)
			breakpoint
			return ERR_FILE_CANT_OPEN
		var parse_err = parse_phiu(file.get_as_text())
		file.close()
		if parse_err:
			Logger.warn(
				"Cannot parse PHIU file `%s'." % level_filepath, null, parse_err
			)
			breakpoint
			return ERR_FILE_CANT_READ

	elif level_filepath.ends_with('tscn'):
		pass
		breakpoint # todo

	elif level_filepath.ends_with('json'):
		var file = File.new()
		var open_err = file.open(level_filepath, File.READ)
		if open_err:
			Logger.warn(
				"Cannot open JSON file `%s'." % level_filepath, null, open_err
			)
			breakpoint
			return ERR_FILE_CANT_OPEN
		var parse_err = parse_phiu(file.get_as_text())
		file.close()
		if parse_err:
			Logger.warn(
				"Cannot parse JSON file `%s'." % level_filepath, null, parse_err
			)
			breakpoint
			return ERR_FILE_CANT_READ

	elif level_filepath.ends_with('png'):
		var image = Image.new()

		var load_err = image.load(level_filepath)
		if OK != load_err:
			Logger.warn("Cannot open PNG file `%s'." % level_filepath, null, load_err)
			breakpoint
			return ERR_FILE_CANT_OPEN
		var parse_err = parse_image_level(image)

		if OK != parse_err:
			Logger.warn("Cannot parse PNG file `%s'." % level_filepath, null, parse_err)
			breakpoint
			return ERR_FILE_CANT_READ

	else:
		breakpoint
		return ERR_INVALID_PARAMETER

	self.filepath = level_filepath
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
