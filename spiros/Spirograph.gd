extends Node2D

const SpirographResource = preload("res://spiros/SpirographResource.gd")

# A customizable, animated spirograph.
# Draws an epicycloïd and animates its properties.

# Will use gradient in spirograph instead if provided
export var spiro_color := Color.plum
export var spiro_line_width := 3.0

export var canvas_width := 0.0
export var canvas_height := 0.0


export(Resource) var spirograph  #:SpirographResource


var circle_properties = {
	'radius':           {'min': 0.0, 'max': 50.0,  'unit': "% of canvas"},
	'radius_variation': {'min': 0.0, 'max': 50.0,  'unit': "% of canvas"},
	'radius_frequency': {'min': 0.0, 'max': 1.618, 'unit': "loops per second"},
	'phase':            {'min': 0.0, 'max': TAU,   'unit': "radians"},
	'phase_variation':  {'min': 0.0, 'max': TAU,   'unit': "radians"},
	'phase_frequency':  {'min': 0.0, 'max': 1.618, 'unit': "loops per second"},
	'speed':            {'min':-1.0, 'max': 1.0,   'unit': "turns per second"},
	'speed_variation':  {'min': 0.0, 'max': 0.25,  'unit': "turns per second"},
	'speed_frequency':  {'min': 0.0, 'max': 0.1,   'unit': "loops per second"},
}


export var boomerang_flat_strength = 2.0
export var boomerang_expo_strength = 1.05
export var boomerang_elasticity = 0.33

var boomerangs = [
	{
		"action": "implode_c0",
		"property": "circle_00_radius",
		"flat_strength_multiplier": 1.0,
		"expo_strength_multiplier": 1.0,
	},
	{
		"action": "implode_c1",
		"property": "circle_01_radius",
		"flat_strength_multiplier": 1.0,
		"expo_strength_multiplier": 1.0,
	},
	{
		"action": "implode_c2",
		"property": "circle_02_radius",
		"flat_strength_multiplier": 1.0,
		"expo_strength_multiplier": 1.0,
	},
	{
		"action": "rotate_c0",
		"property": "circle_00_phase",
		"flat_strength_multiplier": 0.2,
		"expo_strength_multiplier": 1.0,
	},
	{
		"action": "rotate_c1",
		"property": "circle_01_phase",
		"flat_strength_multiplier": 0.2,
		"expo_strength_multiplier": 1.0,
	},
]



func _ready():
	if not self.spirograph:
		self.spirograph = SpirographResource.new()
	build_cache_from_resource_spirograph(self.spirograph)
#	export_to_string(self.spirograph)


func _draw():
	draw_spiro(self.spirograph)

export var stutter := false  # fps limitation if enabled
export var stutter_frequency := 3.0  # times per second
var __stutter_time_since_last_draw := 0.0  # s

var time_speed := 1.0
var time := 0.0
var is_time_processing := true


func _process(delta):
	if not self.visible:
		return
	# delta ~= 0.01666s when not laggy (at 60 FPS)
	if self.is_time_processing:
		self.time += delta * self.time_speed
#		self.time_label.set_text("%.2f" % self.time)
#	process_live_inputs()
	if self.stutter:
		self.__stutter_time_since_last_draw += delta
		if self.__stutter_time_since_last_draw < 1.0 / self.stutter_frequency:
			return  # stutter a little
	
	self.__stutter_time_since_last_draw = 0.0
	update()


#func _input(event):
#	if Input.is_action_just_pressed("clear"):
#		self.spirograph.clear()


# Internal config of spiro
var circles_cache = Array()

func build_cache_from_resource_spirograph(spiro:SpirographResource):
	circles_cache.clear()
	for k in range(spiro.amount_of_circles):
		var circle_cache = Dictionary()
		for parameter_name in circle_properties.keys():
			circle_cache[parameter_name] = spiro.get("circle_%02d_%s" % [k, parameter_name])
		circles_cache.append(circle_cache)
	#print("Built cache from spirograph resource.")


#   _____       _
#  / ____|     (_)
# | (___  _ __  _ _ __ ___
#  \___ \| '_ \| | '__/ _ \
#  ____) | |_) | | | | (_) |
# |_____/| .__/|_|_|  \___/
#        | |
#        |_|


func build_spiro(spiro:SpirographResource):
	var viewport_size = get_viewport().get_visible_rect().size
#	var viewport_side = min(viewport_size.x, viewport_size.y)
	var canvas_size = viewport_size
	if self.canvas_width > 0:
		canvas_size.x = self.canvas_width
	if self.canvas_height > 0:
		canvas_size.y = self.canvas_height
	var canvas_side = min(canvas_size.x, canvas_size.y)
	var spiro_points := Array()
#	var dynamic_angle := 0.0
	
	for i in range(spiro.amount_of_samples):
		
		var dynamic_angle = i * TAU / 60.0 * spiro.draw_speed
		var center = canvas_size * spiro.initial_center
		
		for k in range(spiro.amount_of_circles):
			var circle_cache = self.circles_cache[k]
			var circle_radius = circle_cache['radius']
			var circle_radius_variation = circle_cache['radius_variation']
			var circle_radius_frequency = circle_cache['radius_frequency']
			var circle_phase = circle_cache['phase']
			var circle_phase_variation = circle_cache['phase_variation']
			var circle_phase_frequency = circle_cache['phase_frequency']
			var circle_speed = circle_cache['speed']
			var circle_speed_variation = circle_cache['speed_variation']
			var circle_speed_frequency = circle_cache['speed_frequency']
			
			if null == circle_radius:
				continue
			
			var t = time * TAU * spiro.animation_speed
			center = get_point_on_circle(
				center,
				canvas_side * 0.01 * (circle_radius + circle_radius_variation * sin(t * circle_radius_frequency)),
				(circle_phase + circle_phase_variation * sin(t * circle_phase_frequency)) + dynamic_angle * (circle_speed + circle_speed_variation * sin(t * circle_speed_frequency))
			)
		
		spiro_points.append(center)
	
	return spiro_points


func get_point_on_circle(center, radius, angle):
	return center + radius * Vector2(cos(angle), sin(angle))


#  _____                     _
# |  __ \                   (_)
# | |  | |_ __ __ ___      ___ _ __   __ _
# | |  | | '__/ _` \ \ /\ / / | '_ \ / _` |
# | |__| | | | (_| |\ V  V /| | | | | (_| |
# |_____/|_|  \__,_| \_/\_/ |_|_| |_|\__, |
#                                     __/ |
#                                    |___/

func draw_spiro(spiro:SpirographResource):
	var spiro_points = build_spiro(spiro)
	assert(spiro_points.size() > 1)
	
	if spiro.color_gradient:
		self.spiro_color = spiro.color_gradient.interpolate((cos(time * 0.1) + 1.0) / 2.0)
	
	if self.is_capturing:
		self.spiro_color = Color.white
	
	draw_polyline_custom(spiro_points)


func draw_polyline_custom(spiro_points):
	draw_polyline(
		spiro_points,
		self.spiro_color,
		self.spiro_line_width,
		true  # antialiased
	)
	
	# 2 ** 11
#	var spiro_colors = PoolColorArray()
#	var n = spiro_points.size() * 1.0
#	for i in range(n):
#		spiro_colors.append(Color(i/n, 1.0, 1.0, 1.0))
#	draw_polyline_colors(spiro_points, spiro_colors, 4, true)


func draw_circle_not_disk(center, radius, color=Color.white):
	draw_arc(center, radius, 0, TAU, 42, color)


func draw_point(at_position, radius=2.0, color=Color.white):
	draw_circle(at_position, radius, color)


#  ______                       _
# |  ____|                     | |
# | |__  __  ___ __   ___  _ __| |_
# |  __| \ \/ / '_ \ / _ \| '__| __|
# | |____ >  <| |_) | (_) | |  | |_
# |______/_/\_\ .__/ \___/|_|   \__|
#             | |
#             |_|


#const CompressorSerializer = preload("res://lib/CompressorSerializer.gd")
#
#
#func pickle_spiro(spiro:SpirographResource):
#	var pickle = Array()
#	for k in range(spiro.amount_of_circles):
#		for property_name in self.circle_properties.keys():
#			pickle.append(spiro.get("circle_%02d_%s" % [k, property_name]))
#	return pickle
#
#
#func unpickle_spiro(pickle, into_spiro:SpirographResource):
#	var i = 0
#	var pl = pickle.size()
#	for k in range(into_spiro.amount_of_circles):
#		for property_name in self.circle_properties.keys():
#			if i >= pl:
#				printerr("Looks like the pickle is too short!")
#				continue
#			into_spiro.set(
#				"circle_%02d_%s" % [k, property_name],
#				pickle[i]
#			)
#			i += 1
#
#
#func export_to_string(spiro:SpirographResource):
#	# Compression is only worth it for bigger blobs of data than what we have.
##	var s = CompressorSerializer.compress_resource_pretty(spiro)
##	var s = CompressorSerializer.compress_string(
##		var2str(pickle_spiro(spiro))
##	)
##	prints("Spirograph Exchange String:", s)
#
#	# Instead, let's just use plain var2str
#	var s = var2str(pickle_spiro(spiro))
#	var exchange_label = $"../Menu/VBoxContainer/ExchangeStringLineEdit"
#	exchange_label.set_text(s)



var initial_values = Dictionary()  # property:String => initial_value:float

#func process_live_inputs():
#
##	var freeze_parameters = false
#	if Input.is_action_just_pressed("freeze"):
##		initial_values.clear()
#		for parameter in initial_values:
#			initial_values[parameter] = self.spirograph.get(parameter)
##		freeze_parameters = true
#
#	for boomerang in boomerangs:
#		var action = boomerang['action']
#		var property = boomerang['property']
#		if Input.is_action_just_pressed(action):
#			if not initial_values.has(property):
#				initial_values[property] = self.spirograph.get(property)
#
#		if Input.is_action_pressed(action):
#			var new_value = self.spirograph.get(property)
#			if Input.is_action_pressed("inverter"):
#				new_value /= boomerang_expo_strength * boomerang['expo_strength_multiplier']
#				new_value -= boomerang_flat_strength * boomerang['flat_strength_multiplier']
#			else:
#				new_value *= boomerang_expo_strength * boomerang['expo_strength_multiplier']
#				new_value += boomerang_flat_strength * boomerang['flat_strength_multiplier']
#			self.spirograph.set(property, new_value)
#		else:
#			if initial_values.has(property):
#				var fallback_intention = (
#					initial_values[property] - \
#					self.spirograph.get(property)
#				)
#
#				self.spirograph.set(property,
#					self.spirograph.get(property) + \
#					boomerang_elasticity * fallback_intention
#				)
#
#				if abs(fallback_intention) < 0.001:
#					initial_values.erase(property)
#
#	build_cache_from_resource_spirograph(self.spirograph)
#	update_menu(self.spirograph)




#  _    _ _____
# | |  | |_   _|
# | |  | | | |
# | |  | | | |
# | |__| |_| |_
#  \____/|_____|
#
#

var __changes_coming_from_export := false


var is_capturing := false
var exported_sprite_size := 512

func export_to_sprite():
	var previous_window_size = OS.window_size
	OS.window_size = Vector2(self.exported_sprite_size, self.exported_sprite_size)
#	menu.visible = false
	self.is_capturing = true
	var time_before = self.time
	for _i in range(3):
#		self.time = 0
		yield(get_tree(), "idle_frame")
	self.time = time_before
	
	var now = OS.get_datetime(true)
	var output_path = "res://spirograph_%04d%02d%02dT%02d%02d%02d.png" % [
		now['year'],
		now['month'],
		now['day'],
		now['hour'],
		now['minute'],
		now['second'],
	]
	var image : Image = get_tree().get_root().get_texture().get_data()
	image.flip_y()
	var backgroundColor = ProjectSettings.get("rendering/environment/default_clear_color")
	var imageWithAlpha = color_to_alpha(image, backgroundColor)
	imageWithAlpha.save_png(output_path)
	
	OS.window_size = previous_window_size
#	menu.visible = true
	self.is_capturing = false


## Parses an ISO-8601 date string to a datetime dictionary that can be parsed by Godot.
## Note that we don't use ISO-8601 in filenames
## Not sure why we have this parser
func parse_date(iso_date: String) -> Dictionary:
	var parsed_date := iso_date.split("T")[0].split("-")
	var parsed_time := iso_date.split("T")[1].trim_suffix("Z").split(":")

	return {
		year = parsed_date[0],
		month = parsed_date[1],
		day = parsed_date[2],
		hour = parsed_time[0],
		minute = parsed_time[1],
		second = parsed_time[2],
	}


func color_to_alpha(image:Image, color:Color) -> Image:
	"""
	Trying to get a GIMP-like "color to alpha".
	This creates a new Image because I could not get alpha.
	Best make this a mutation of input image if we can instead.
	"""
	var imageWithAlpha := Image.new()
	imageWithAlpha.create(
		int(image.get_size().x),
		int(image.get_size().y),
		false,
		Image.FORMAT_RGBA8
	)
	image.convert(Image.FORMAT_BPTC_RGBA)
	image.lock()
	imageWithAlpha.lock()
	for x in range(image.get_size().x):
		for y in range(image.get_size().y):
			var pixel_color : Color = image.get_pixel(x, y)
			var N : Color = pixel_color
			var B : Color = color
			# A = max( abs(N.r - B.r), abs(N.g - B.g), abs(N.b - B.b)  ) 
			var alpha = max(abs(N.r - B.r), max(abs(N.g - B.g), abs(N.b - B.b)))
			var A = alpha
			# N = A * F  +  (1 - A) * B;
			var F : Color = Color()
			F.r = (N.r - (1 - A) * B.r) / A
			F.g = (N.g - (1 - A) * B.g) / A
			F.b = (N.b - (1 - A) * B.b) / A
			F.a = A
			
			imageWithAlpha.set_pixel(x, y, F)
	
	image.unlock()
	imageWithAlpha.unlock()
	
	return imageWithAlpha


#onready var tween = $Tween
#		tween.interpolate_property(
#			self.spirograph, # object: Object,
#			"circle_%02d_%s" % [0, 'radius'],  #property: NodePath,
#			implosion_initial_circle_00_radius, #initial_val: Variant,
#			final_val: Variant,
#			duration: float,
#			trans_type: TransitionType = 0,
#			ease_type: EaseType = 2,
#			delay: float = 0,
#		)
#
#		tween.start()

