# From https://github.com/Zylann/godot_texture_generator/blob/master/addons/zylann.tgen/util/jsonify.gd


static func jsonify(data):
	
	match typeof(data):
		
		TYPE_STRING, \
		TYPE_BOOL, \
		TYPE_INT, \
		TYPE_REAL:
			return data
		
		TYPE_ARRAY:
			for i in len(data):
				data[i] = jsonify(data[i])
			return data
		
		TYPE_DICTIONARY:
			for k in data:
				data[k] = jsonify(data[k])
			return data
		
		TYPE_VECTOR2:
			return {
				"x": data.x,
				"y": data.y
			}

		TYPE_COLOR:
			return {
				"r": data.r,
				"g": data.g,
				"b": data.b,
				"a": data.a
			}

		TYPE_RECT2:
			return {
				"x": data.position.x,
				"y": data.position.y,
				"w": data.size.x,
				"h": data.size.y
			}

		TYPE_VECTOR3:
			return {
				"x": data.x,
				"y": data.y,
				"z": data.z
			}
		
		_:
			printerr("Unhandled data type: ", data)
			breakpoint

enum REGEXES {
	VECTOR2,
}

const regexes := {
	REGEXES.VECTOR2: null,  # lazily compiled and memoized here (const → nope)
}

static func compile_regexes_lazily() -> int:
	if null == regexes[REGEXES.VECTOR2]:
		var vec2_regex := RegEx.new()
		# TODO: support floats as well, and scientific notation
		var compiled := vec2_regex.compile(
			" *(Vector2)? *[(] *" +
			"(?<x>[-+]?[0-9]+)" +
			" *, *" +
			"(?<y>[-+]?[0-9]+)" +
			" *[)] *"
		)
		if OK != compiled:
			breakpoint
			return compiled
		
		regexes[REGEXES.VECTOR2] = vec2_regex
	
	return OK


static func godotify_key(data):
	
	match typeof(data):
		
		TYPE_STRING:
			
			# As JSON prints Dictionary keys as String, this recovers Vectors
			
			if OK != compile_regexes_lazily():
				return data
			
			var resultVector2: RegExMatch = regexes[REGEXES.VECTOR2].search(data)
			if resultVector2:
				return Vector2(
					str2var(resultVector2.strings[resultVector2.names['x']]),
					str2var(resultVector2.strings[resultVector2.names['y']])
				)
			
			# … Vector3, etc.
			
			return data
		
		_:
			return data


static func godotify(data):
	
	match typeof(data):
		
		TYPE_ARRAY:
			
			for i in len(data):
				data[i] = godotify(data[i])
			return data
		
		TYPE_DICTIONARY:
			
			match len(data):
				2:
					if data.has("x") and data.has("y"):
						return Vector2(data.x, data.y)
				3:
					if data.has("x") and data.has("y") and data.has("z"):
						return Vector3(data.x, data.y, data.z)
				4:
					if data.has("r") and data.has("g") and data.has("b") and data.has("a"):
						return Color(data.r, data.g, data.b, data.a)
					
					elif data.has("x") and data.has("y") and data.has("w") and data.has("h"):
						return Rect2(data.x, data.y, data.w, data.h)
			
			var data_godotified := Dictionary()
			for k in data:
				data_godotified[godotify_key(k)] = godotify(data[k])
			return data_godotified
		
		_:
			return data

