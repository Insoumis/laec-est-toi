tool
extends Node2D
#class_name Level  # (┛◉.◉)┛彡┻━┻

# A Level handles:
# - a bunch of items
# - a lattice of cells
# - a tilemap of ground tiles
# - applying the game rules
# - win and defeat animations
# - its own history (UNDO IS ODNU)
# - … ?
# - … ?
# 
# A handy blackboard for new features, until it's refactoring time.
# 
# A Level should be able to run in the Editor.
# Keep in mind that Singletons are not available in the Editor.
# Some features are explicitely disabled in the editor, such as:
# - Alchemical Sentences  (THING IS THING)
# - Stuffing Sentences  (THING HAS THING) ← those are ok to have?
# - Making Sentences  (THING MAKE THING)
# - and the application of qualities
# 
# This file is getting pretty long.
# Perhaps some of the Rules could be moved somewhere else?
# Qualities should perhaps go each in their own file.
# We're going to try to move words into their own files.
# Incrementally.  We'd love to discuss this with you if you have ideas.

# We have to preload instead of class_name due to bugs in Godot on Windows
const Item = preload("res://addons/laec-is-you/entity/Item.gd")
const ItemScene = preload("res://core/Item.tscn")
const ItemsPalette = preload("res://core/ItemsPalette.gd")
const LevelReference = preload("res://core/LevelReference.gd")

# Only levels with this property set to true will be used
# in the completion score calculus.
export var contribute_to_completion_score := false

# An ItemPalette resource is expected here.
# Do not read from this.  Prefer reading from __items_palette,
# which will always be set to a default palette. (thanks to 1x1 pixel images)
# This allows us to instantiate a default without setting this public prop
# so the editor mode won't save the Resource, but we'll see colors.
export(Resource) var items_palette# : ItemsPalette
var __items_palette : ItemsPalette

# These are set automatically in the Editor, by our Wizard,
# to translation string identifiers.  (eg: "level.MyLevel.title")
# To set the actual title to your level, we'll use PO translation files.
# Or you can use the xxx_custom properties for simplicity.
export(String) var title := ""
export(String) var excerpt := ""
export(String) var link := ""

# Local overrides to bypass I18N shenanigans
# Sadly, these are detected by babel and are added to the l10n pool.
# They should not, ideally, but it is how it is.
export(String) var title_custom := ""
export(String, MULTILINE) var excerpt_custom := ""
export(String) var link_custom := ""


# Achievements are triggered under certain conditions.
# These conditions are written in the fashion of the game.
# For I18N to kick in, your achievements MUST be their own `.tres` files.
export(Resource) var achievement_a
export(Resource) var achievement_b
export(Resource) var achievement_c
# We can't use this syntax
#export(Achievement) var achievement_a
# see https://github.com/godotengine/godot-proposals/issues/18


# Forward level this level leads to when complete.
# If not set, will go back up in scene ancestry.
export(String, FILE, "*.tscn") var forward_level_path: String


# Deactivates inputs, achievements, etc.  Best never enable this.
# This is exported because it's convenient for me,
# I hope the name dissuades usage enough.
export var editor_preview_no_interaction := false

# Deactivates inputs and buttons
export var no_interaction := false

# Useful in demos and the movement tutorial
export var skip_victory_screen := false


signal level_completed(level, winning_cells)

signal before_action_moved(direction)
signal after_action_moved(direction)
signal before_action_passed()
signal after_action_passed()
signal before_action_undoed()
signal after_action_undoed()
signal before_action_executed()
signal after_action_executed()


onready var items_layer: Node2D = $Items
onready var effects_layer: Node2D = $Effects

onready var mouse_gui: HexagonGui = find_node('HexagonGui')
onready var home_gui_button: Control = find_node('HomeGuiButton')
onready var undo_gui_button: Control = find_node('UndoGuiButton')
onready var undo_button: Button = find_node('UndoButton')
onready var sherpa: Node2D = find_node('Sherpa')


# Deactivates WIN and interactions.
# Set to true in the replay on the victory screen.
var replay_run := false


# Deactivates PAUSE menu, perhaps record a solution (best use signals instead)
# Only enabled on the level spawned in the ingame editor after pressing PLAY.
var editor_live_preview := false


# A "dictionary" of Cell => Array of Items, with hex goodies
# Kind of like a TileMap, but allows multiple things per tile,
# and it's not a Node, just a data structure.
var cell_lattice : HexagonalLattice


# Helps with THING IS|MAKE NOT THING transmutations.
# This is set at the beginning of the level, from initial items.
# This includes all thing concepts, including from text items.
var __unique_nouns_available : Array


# This is set to true by the end of _ready()
# Helps when we want to yield on ready, to not yield forever
var is_ready := false



# Some more properties are defined below.
# It's not the usual practice, but we found that
# it helps when refactoring these big-ass scripts.


#  _      _  __                     _
# | |    (_)/ _|                   | |
# | |     _| |_ ___  ___ _   _  ___| | ___
# | |    | |  _/ _ \/ __| | | |/ __| |/ _ \
# | |____| | ||  __/ (__| |_| | (__| |  __/
# |______|_|_| \___|\___|\__, |\___|_|\___|
#                         __/ |
#                        |___/
# 
# Children classes may override ready() since they can't override _ready().
# The same goes for _process() and others.
# We only put mirror calls in the _methods() to bypass class inheritance bugs.


func _init():
	init()


func _ready():
	ready()


func _process(delta):
	process(delta)


func _enter_tree():
	enter_tree()


func _exit_tree():
	exit_tree()


func _input(event):
	handle_input(event)


func queue_free():
	#print("Queuing for free level %s" % name)
	.queue_free()


func free():
	#print("Freeing level %s" % name)
	.free()


func init():
	reset_cell_lattice()


func ready():
	
	if self.is_ready:
		return
	
	# This initial turn would handle the initial
	# setting of item flags from the rules.
	# But we don't want this.  Hence the ItemWizard.
	#spend_turn()
	
	if Engine.is_editor_hint():
		fix_gui_locks()
		rename_root_node()
	else:
		if should_not_interact():
			self.home_gui_button.hide()
			self.undo_gui_button.hide()
	if is_editor_preview():
		set_process(false)  # _process() still happens eventually… weird
	
	# Color palettes can be set per-level
	setup_palettes()
	
	# We're bypassing localization with `xxx_custom` props,
	# but it's there and working.
	setup_l10n()
	
	# We need to register the Items, it's like a cache
	# so we don't look at the scene tree all the time. (it's super slow)
	register_all_items()
	reindex_lattice()

	# We want to write the initial state in history,
	# so we can get back to it by pressing undo after the first action.
	write_history()
	
	# Collect unique nouns on startup, eg. for NOT THING resolution
	self.__unique_nouns_available = get_unique_nouns_available()
	
	ready_autoplay()
	
	restart_level_chronometer()
	
	self.is_ready = true


func process(delta):
	if not is_editor_preview():
		handle_process_inputs(delta)
	process_autoplay(delta)
	process_screen_shake(delta)


func handle_process_inputs(delta):
	# I know it's slightly faster to NOT use functions,
	# especially in the main loop, but it looks neat like this:
	handle_keyboard_inputs_on_process(delta)
	handle_gauge_arrows_inputs_on_process(delta)
	handle_mouse_inputs_on_process(delta)
	handle_joypad_inputs_on_process(delta)


func enter_tree():
	if is_editor_preview():
		return
	enable_inputs_after_delay()


func exit_tree():
	if is_editor_preview():
		return
	stop_using_drag_joystick()


#  __  __      _            _       _
# |  \/  |    | |          | |     | |
# | \  / | ___| |_ __ _  __| | __ _| |_ __ _
# | |\/| |/ _ \ __/ _` |/ _` |/ _` | __/ _` |
# | |  | |  __/ || (_| | (_| | (_| | || (_| |
# |_|  |_|\___|\__\__,_|\__,_|\__,_|\__\__,_|
#
#

# Oh my.  Not pretty, but it works.
# I don't have the time to design something reusable and great
# that would combine I18N and custom overrides.  Here be dragons.
var title_displayed : String setget ,get_title_displayed
var excerpt_displayed : String setget ,get_excerpt_displayed
var link_displayed : String setget ,get_link_displayed


func get_title_displayed() -> String:
	if self.title_custom != "":
		return self.title_custom
	if self.title != "":
		return tr(self.title)
	return "?¿?"


func get_excerpt_displayed() -> String:
	if self.excerpt_custom != "":
		return self.excerpt_custom
	if self.excerpt != "":
		return tr(self.excerpt)
	return "…"


func get_link_displayed() -> String:
	if self.link_custom != "":
		return self.link_custom
	if self.link != "":
		return tr(self.link)
	return ""


#  _____ _      _    _ _
# |  __ (_)    | |  | (_)
# | |__) |  ___| | _| |_ _ __   __ _
# |  ___/ |/ __| |/ / | | '_ \ / _` |
# | |   | | (__|   <| | | | | | (_| |
# |_|   |_|\___|_|\_\_|_|_| |_|\__, |
#                               __/ |
#                              |___/

# Used to reset the level to its beginning in order to play the replay.
# The reset action could also use this in the future, perhaps. (maybe not)
var initial_pickle: Dictionary


func load_from_string(serialized: String) -> int:
	
	if not self.is_ready:
		yield(self, "ready")
	
	var level_reference := LevelReference.new()
	var parse_err = level_reference.parse_phiu(serialized)
	if OK != parse_err:
		return parse_err
	
	var data = level_reference.pickle
	return load_from_pickle(data)


func load_from_pickle(data: Dictionary) -> int:
	
	if not self.is_ready:
		yield(self, "ready")
	
	if not (data is Dictionary):
		return ERR_INVALID_PARAMETER
	
	if not data.has('terrain'):
		return ERR_INVALID_PARAMETER
	
	if not data.has('concepts'):
		return ERR_INVALID_PARAMETER
	
#	if not data.has('meta') or not (data['meta'] is Dictionary):
#		breakpoint
#		return ERR_INVALID_PARAMETER
	
	var hex_tilemap = get_tile_map()
	hex_tilemap.clear()
	
	for tile in data.get('terrain', {}).keys():
		hex_tilemap.set_cellv(tile, data['terrain'][tile])
	
	self.actions_history.clear()
	self.recorded_solution = ""
#	for item in get_all_items():
	if self.items_layer:
		for item in self.items_layer.get_children():
			item.get_parent().remove_child(item)
			item.queue_free()
	deregister_all_items()
	
	for item_pickle in data.get('concepts', []):
		var item = spawn_item()
		assert(item)
		
		# We could perhaps remove the self.cell_lattice shenanigans with
		# a pickle parameter in spawn_item() ?
		self.cell_lattice.remove_thing(item)
		item.from_pickle(item_pickle)
		self.cell_lattice.add_thing_on_cell(item, item.cell_position)
		
		item.reposition()
		item.update_aesthetics()
	
	self.camera.zoom = data.get('zoom', Vector2.ONE)
	
	if data.has('meta') and (data['meta'] is Dictionary):
		self.title_custom = data['meta'].get('title', "")
		self.excerpt_custom = data['meta'].get('congratulation', "")
	
	register_all_items()
	reindex_lattice()
	# We assume the level was empty during ready ; if it was not, chaos :
#	self.history.pop_back()
	self.history.clear()
	write_history()
	
	return OK


func terrain_to_pickle() -> Dictionary:
	var pickle := Dictionary()
	
	var hex_tilemap = get_tile_map()
	for tile in hex_tilemap.get_used_cells():
		pickle[tile] = hex_tilemap.get_cellv(tile)
	
	return pickle


func concepts_to_pickle() -> Array:
	var pickle := Array()
	
	for item in get_all_items():
		if not (item is Item):
			breakpoint
			continue
		pickle.append(item.to_pickle())
	
	return pickle


func to_pickle() -> Dictionary:
	return {
		'terrain': terrain_to_pickle(),
		'concepts': concepts_to_pickle(),
		'zoom': self.camera.zoom,
		# meta too?  FIXME
	}


#  _   _             _             _   _
# | \ | |           (_)           | | (_)
# |  \| | __ ___   ___  __ _  __ _| |_ _  ___  _ __
# | . ` |/ _` \ \ / / |/ _` |/ _` | __| |/ _ \| '_ \
# | |\  | (_| |\ V /| | (_| | (_| | |_| | (_) | | | |
# |_| \_|\__,_| \_/ |_|\__, |\__,_|\__|_|\___/|_| |_|
#                       __/ |
#                      |___/


func go_forward() -> void:
	if self.forward_level_path and Game:
		#print("going forward")
		Game.switch_to_level(self.forward_level_path, true, false)
	else:
		go_back()


func go_back_to_map() -> void:
	go_back()


func go_back() -> void:
	if not Game:
		printerr("Game singleton is not available in Level.go_back()")
		return
	var _gone = Game.go_back()


#   _____ _        _
#  / ____| |      | |
# | (___ | |_ __ _| |_ _   _ ___
#  \___ \| __/ _` | __| | | / __|
#  ____) | || (_| | |_| |_| \__ \
# |_____/ \__\__,_|\__|\__,_|___/
#
#


func is_editor_preview():
	return Engine.is_editor_hint() or self.editor_preview_no_interaction


func has_no_victory_screen() -> bool:
	return self.skip_victory_screen


func is_dummy_run() -> bool:
	return (
		self.is_test_run
		or
		self.replay_run
	)


func should_not_interact():
	return self.no_interaction or self.editor_preview_no_interaction


#  _   _                 _
# | \ | |               (_)
# |  \| | __ _ _ __ ___  _ _ __   __ _
# | . ` |/ _` | '_ ` _ \| | '_ \ / _` |
# | |\  | (_| | | | | | | | | | | (_| |
# |_| \_|\__,_|_| |_| |_|_|_| |_|\__, |
#                                 __/ |
#                                |___/
# Name automation was useful for L10N, when we use Godot to make levels.
# Nowadays, it's not as useful.  Perhaps we will disable it.

func get_unique_name() -> String:
#	print("filename", self.filename)
	var re = RegEx.new()
	re.compile("res://(?<rootdir>levels|features|)?/?(?<namespace>.+)/(?<name>[^/]+)[.]tscn")
	var result = re.search(self.filename)
	var unique_name := ""
	if result:
		if result.strings[result.names['namespace']] == "core":
			unique_name = "%s" % [result.strings[result.names['name']]]
		else:
			unique_name = "%s/%s" % [result.strings[2], result.strings[3]]
	else:
		unique_name = self.filename.substr(13, self.filename.length()-5-13)
	
	return unique_name


func get_somewhat_unique_name() -> String:
	var unique_name = get_unique_name()
	
	var i = unique_name.find_last('/')
	if 0 <= i and i+1 < unique_name.length():
		unique_name = unique_name.substr(i+1)
	
	return unique_name


func rename_root_node() -> void:
	set_name(get_somewhat_unique_name())


#  _     __  ___  _   _
# | |   /_ |/ _ \| \ | |
# | |    | | | | |  \| |
# | |    | | | | | . ` |
# | |____| | |_| | |\  |
# |______|_|\___/|_| \_|
#
# Localization


func setup_l10n() -> void:
	var unique_name = get_somewhat_unique_name()
	self.title = "level.%s.title" % [unique_name]
#	self.subtitle = "level.%s.subtitle" % [unique_name]
	self.excerpt = "level.%s.excerpt" % [unique_name]
	self.link = "level.%s.link" % [unique_name]
	
	for i in range(2):
		var letter = char(ord('a') + i)
		var achievement = get("achievement_%s" % letter)
		if achievement:
			achievement.title = "level.%s.%s.title" % [
				unique_name,
				achievement.snake_identifier,
			]


#  _           _   _   _
# | |         | | | | (_)
# | |     __ _| |_| |_ _  ___ ___  ___
# | |    / _` | __| __| |/ __/ _ \/ __|
# | |___| (_| | |_| |_| | (_|  __/\__ \
# |______\__,_|\__|\__|_|\___\___||___/
#
#

# CAREFUL: these options do not change the TileMap config, you have to do it.
# We could configure the Items TileMap from these as well, I'm just in a hurry.
export var lattice_hex_size := 64.0
export var lattice_aspect_ratio := 0.82
export var lattice_kenney := true


# deprecated
func reset_cell_lattice() -> void:
	reset_items_lattice()


func reset_items_lattice() -> void:
	self.cell_lattice = HexagonalLattice.new()
	self.cell_lattice.hex_size = self.lattice_hex_size
	self.cell_lattice.aspect_ratio = self.lattice_aspect_ratio
	self.cell_lattice.kenney = self.lattice_kenney


func get_items_lattice() -> HexagonalLattice:
	return self.cell_lattice


#  _____      _      _   _
# |  __ \    | |    | | | |
# | |__) |_ _| | ___| |_| |_ ___  ___
# |  ___/ _` | |/ _ \ __| __/ _ \/ __|
# | |  | (_| | |  __/ |_| ||  __/\__ \
# |_|   \__,_|_|\___|\__|\__\___||___/
#


func setup_palettes() -> void:
	if self.items_palette:
		# Engine bug: https://github.com/godotengine/godot/issues/33079
#		self.__items_palette = self.items_palette.duplicate(true) as ItemsPalette
		self.__items_palette = self.items_palette.duplicate() as ItemsPalette
	else:
		self.__items_palette = ItemsPalette.new()
	self.__items_palette.complete_with_defaults()


func get_color_for_concept(concept: String, is_text: bool) -> Color:
	if not self.__items_palette:
		breakpoint  # must yield on level ready?
		return Color.white
	if not (self.__items_palette is ItemsPalette):
		breakpoint  # what are you doing? use ItemPalette please
		return Color.white
	return self.__items_palette.get_color(
		('text_' if is_text else '') + concept,
		Color.white
	)


#   _____
#  / ____|                         /\
# | (___   ___ ___ _ __   ___     /  \__      ____ _ _ __ ___ _ __   ___  ___ ___
#  \___ \ / __/ _ \ '_ \ / _ \   / /\ \ \ /\ / / _` | '__/ _ \ '_ \ / _ \/ __/ __|
#  ____) | (_|  __/ | | |  __/  / ____ \ V  V / (_| | | |  __/ | | |  __/\__ \__ \
# |_____/ \___\___|_| |_|\___| /_/    \_\_/\_/ \__,_|_|  \___|_| |_|\___||___/___/
#
#

func get_scene_viewport() -> Viewport:
	var parent = self
	while parent and not (parent is Viewport):
		parent = parent.get_parent()
	assert(parent is Viewport, "Scene viewport was not found.")
	return parent


# Our terrain tilemap.
# Like an onready, but works when the level is not added to the tree yet.
var __tile_map: TileMap

func get_tile_map() -> TileMap:
	if __tile_map and is_instance_valid(__tile_map):
		return __tile_map
	__tile_map = find_node('HexagonalTileMap', true, false)
	assert(__tile_map, 'HexagonalTileMap was not found in the scene.')
	return __tile_map


#  _    _           _
# | |  | |         | |
# | |__| |_   _  __| |
# |  __  | | | |/ _` |
# | |  | | |_| | (_| |
# |_|  |_|\__,_|\__,_|
#
#

var mouse_gui_fill_sensitivity = 0.025 / 0.016


func show_mouse_gui():
	mouse_gui.release_direction()
	mouse_gui.set_visible(true)


func hide_mouse_gui():
	mouse_gui.release_direction()
	mouse_gui.set_visible(false)


func move_mouse_gui_at_position(here: Vector2) -> void:
	mouse_gui.position = here


func mark_direction_in_mouse_gui(direction: String):
	mouse_gui.mark_direction(direction)


func release_direction_in_mouse_gui():
	mouse_gui.release_direction()


func fill_mouse_gui(how_much := 1.0):
	mouse_gui.fill(how_much)


func empty_mouse_gui():
	release_direction_in_mouse_gui()
	fill_mouse_gui(0)


#  _____                   _
# |_   _|                 | |
#   | |  _ __  _ __  _   _| |_ ___
#   | | | '_ \| '_ \| | | | __/ __|
#  _| |_| | | | |_) | |_| | |_\__ \
# |_____|_| |_| .__/ \__,_|\__|___/
#             | |
#             |_|

var __is_accepting_inputs := false

var action_cooldown_base := 0.16   # seconds (static, initial config)
var action_cooldown := 0.16   # seconds (may vary during repeated UNDO)
var last_action_stamp := 0.0  # milliseconds, should be private probably


func handle_input(event):
	
	if not is_accepting_inputs():
		return
	
	if event is InputEventJoypadButton or event is InputEventKey:
#		if Input.is_action_just_pressed("undo"):
#			if editor_live_preview:
#				stop_accepting_inputs()
#				go_back()

		if (Input.is_action_just_pressed("pause") or
			Input.is_action_just_pressed("escape")):
			stop_accepting_inputs()
			Game.go_to_pause_menu(self)
		if Input.is_action_just_released("restart"):
			stop_accepting_inputs()
			Game.reset_level()
		if Input.is_action_just_released("pass"):
			if not is_cooling_down_between_actions():
				try_pass()
		if Input.is_action_just_released("cheat"):
			start_any_autoplay()
		if Input.is_action_just_pressed("grid"):
			$HexagonalGridLines.visible = not $HexagonalGridLines.visible
	
	if event is InputEventMouse:
		handle_mouse_inputs(event)


func start_accepting_inputs() -> void:
	self.__is_accepting_inputs = true
	# … signals


func stop_accepting_inputs() -> void:
	self.__is_accepting_inputs = false
	hide_mouse_gui()
	# … signals


func is_accepting_inputs() -> bool:
	return (
		not is_editor_preview()
		and
		not self.no_interaction
		and
		not self.replay_run
		and
		self.__is_accepting_inputs
	)


func enable_inputs_after_delay():
	
	if self.is_test_run:
		start_accepting_inputs()  # why?
	else:
		# best connect to a signal here instead of yielding
		yield(get_tree().create_timer(0.8), "timeout")
		start_accepting_inputs()
		# like so?
#		get_tree().create_timer(0.8).connect("timeout", self, "start_accepting_inputs")


func is_cooling_down_between_actions(now_ms:=-1, extra_cooldown_ms:=0) -> bool:
	if now_ms < 0:
		now_ms = OS.get_ticks_msec()
	if now_ms < self.last_action_stamp + get_action_cooldown_ms() + extra_cooldown_ms:
		return true
	return false


func start_action_cooldown(now_ms: int = -1) -> void:
	if now_ms < 0:
		now_ms = OS.get_ticks_msec()
	self.last_action_stamp = now_ms % (1 << 30)


func get_action_cooldown():
	return action_cooldown


func get_action_cooldown_ms():
	return get_action_cooldown() * 1000


#                                     _____
#     /\                             / ____|
#    /  \   _ __ _ __ _____      __ | |  __  __ _ _   _  __ _  ___
#   / /\ \ | '__| '__/ _ \ \ /\ / / | | |_ |/ _` | | | |/ _` |/ _ \
#  / ____ \| |  | | | (_) \ V  V /  | |__| | (_| | |_| | (_| |  __/
# /_/    \_\_|  |_|  \___/ \_/\_/    \_____|\__,_|\__,_|\__, |\___|
#                                                        __/ |
#                                                       |___/

# How fast the arrow gauge fills up
var arrow_gauge_sensitivity := 5.0


# Each gauge goes from 0 to 1.
# At 1, a move is triggered in the related direction.
#var __arrow_gauge_by_direction := Dictionary()  # String|Vector2  =>  float
var __arrow_gauge_by_direction := {
	Directions.UP_RIGHT: 0.0,
	Directions.RIGHT: 0.0,
	Directions.DOWN_RIGHT: 0.0,
	Directions.UP_LEFT: 0.0,
	Directions.LEFT: 0.0,
	Directions.DOWN_LEFT: 0.0,
}
var __arrow_gauge_gui: Node2D
var __arrow_gauge_hint: Node2D
var __arrow_gauge_current_rotation := 0.0
var __arrow_gauge_target_direction = null  # not typed since nullable


func handle_gauge_arrows_inputs_on_process(delta: float):
	# This could be enabled on-demand, and perhaps even disabled on idle,
	# in order to save performance and CPU.
	
	if (
		not is_accepting_inputs()
		or
		is_cooling_down_between_actions()
		or
		is_in_limbo()
	):
		hide_arrow_gauge()
		hide_arrow_gauge_hints()
		return
	
	var has_tried_to_move := false
	var has_moved := false
	
	var input_intended_direction
	
	if (
		Input.is_action_pressed("move_gauge_right")
	):
		if Input.is_action_pressed("move_gauge_down"):
			input_intended_direction = Directions.DOWN_RIGHT
		elif Input.is_action_pressed("move_gauge_up"):
			input_intended_direction = Directions.UP_RIGHT
		else:
			input_intended_direction = Directions.RIGHT
	
	if (
		Input.is_action_pressed("move_gauge_left")
	):
		if Input.is_action_pressed("move_gauge_down"):
			input_intended_direction = Directions.DOWN_LEFT
		elif Input.is_action_pressed("move_gauge_up"):
			input_intended_direction = Directions.UP_LEFT
		else:
			input_intended_direction = Directions.LEFT
	
	if (
		null == input_intended_direction
		and
		Input.is_action_pressed("move_gauge_up")
	):
		show_arrow_gauge_hint(Directions.UP)
	elif (
		null == input_intended_direction
		and
		Input.is_action_pressed("move_gauge_down")
	):
		show_arrow_gauge_hint(Directions.DOWN)
	else:
		hide_arrow_gauge_hints()
		
	self.__arrow_gauge_target_direction = input_intended_direction
	
	for direction in self.__arrow_gauge_by_direction:
		if direction == input_intended_direction:
			augment_arrow_gauge(input_intended_direction, (
				delta
				*
				arrow_gauge_sensitivity
			))
			show_arrow_gauge()
		else:
			augment_arrow_gauge(direction, (
				-0.38  # reduce slower than augment
				*
				delta
				*
				arrow_gauge_sensitivity
			))
	
	if null == input_intended_direction:
		hide_arrow_gauge()
		return
	
	trigger_arrow_gauge_perhaps()


func augment_arrow_gauge(input_intended_direction, amount:float):
	self.__arrow_gauge_by_direction[input_intended_direction] = min(
#		self.__arrow_gauge_by_direction[input_intended_direction] 
		1.0,
		max(
			0.0,
			self.__arrow_gauge_by_direction[input_intended_direction] + amount
		)
	)


func show_arrow_gauge():
	if not self.__arrow_gauge_target_direction:
		return
	var yous = get_items_that_are_you()
	if not yous:
		return
	var target_item = yous[0]
	
	if not self.__arrow_gauge_gui:
		self.__arrow_gauge_gui = preload("res://guis/ArrowGaugeGui.tscn").instance()
		effects_layer.add_child(self.__arrow_gauge_gui)
	
	self.__arrow_gauge_gui.fill_gauge(self.__arrow_gauge_by_direction[self.__arrow_gauge_target_direction])
	self.__arrow_gauge_gui.rotation = Directions.get_rotation(self.__arrow_gauge_target_direction)
	self.__arrow_gauge_gui.position = target_item.position
	self.__arrow_gauge_gui.visible = true


func hide_arrow_gauge():
	if not self.__arrow_gauge_gui:
		return
	if not self.__arrow_gauge_gui.visible:
		return
	self.__arrow_gauge_gui.visible = false


func show_arrow_gauge_hint(direction_string: String):
	var yous = get_items_that_are_you()
	if not yous:
		return
	var target_item = yous[0]
	if not self.__arrow_gauge_hint:
		self.__arrow_gauge_hint = preload("res://guis/ArrowGaugeHint.tscn").instance()
		self.effects_layer.add_child(self.__arrow_gauge_hint)
	self.__arrow_gauge_hint.rotation = TAU * 0.5 if direction_string == Directions.DOWN else 0
	self.__arrow_gauge_hint.position = target_item.position
	self.__arrow_gauge_hint.visible = true


func hide_arrow_gauge_hints() -> void:
	if not self.__arrow_gauge_hint:
		return
	if not self.__arrow_gauge_hint.visible:
		return
	self.__arrow_gauge_hint.visible = false


func trigger_arrow_gauge_perhaps():
	for direction in self.__arrow_gauge_by_direction:
		var gauge = self.__arrow_gauge_by_direction[direction]
		if 1.0 <= gauge:
			self.__arrow_gauge_by_direction[direction] = 0.0
			var _has_moved = try_move(direction)
			break


#  _  __          _                         _
# | |/ /         | |                       | |
# | ' / ___ _   _| |__   ___   __ _ _ __ __| |
# |  < / _ \ | | | '_ \ / _ \ / _` | '__/ _` |
# | . \  __/ |_| | |_) | (_) | (_| | | | (_| |
# |_|\_\___|\__, |_.__/ \___/ \__,_|_|  \__,_|
#            __/ |
#           |___/

func handle_keyboard_inputs_on_process(_delta) -> void:
	if not is_accepting_inputs():
		return
	if is_cooling_down_between_actions():
		return

	var can_move : bool = not is_in_limbo()
	var has_moved := false
	var has_tried_to_move := false
	
	if can_move:
		if (
			(not has_moved)
			and
			Input.is_action_pressed("move_right")
			and
			Input.is_action_pressed("move_up")
		):
			has_tried_to_move = true
			has_moved = try_move(Directions.UP_RIGHT)
		if (
			(not has_moved)
			and
			Input.is_action_pressed("move_left")
			and
			Input.is_action_pressed("move_up")
		):
			has_tried_to_move = true
			has_moved = try_move(Directions.UP_LEFT)
		if (
			(not has_moved)
			and
			Input.is_action_pressed("move_right")
			and
			Input.is_action_pressed("move_down")
		):
			has_tried_to_move = true
			has_moved = try_move(Directions.DOWN_RIGHT)
		if (
			(not has_moved)
			and
			Input.is_action_pressed("move_left")
			and
			Input.is_action_pressed("move_down")
		):
			has_tried_to_move = true
			has_moved = try_move(Directions.DOWN_LEFT)
		if (not has_moved) and Input.is_action_pressed("move_right"):
			has_tried_to_move = true
			has_moved = try_move(Directions.RIGHT)
		if (not has_moved) and Input.is_action_pressed("move_up_right"):
			has_tried_to_move = true
			has_moved = try_move(Directions.UP_RIGHT)
		if (not has_moved) and Input.is_action_pressed("move_up"):
			has_tried_to_move = true
			has_moved = try_move(Directions.UP)
		if (not has_moved) and Input.is_action_pressed("move_up_left"):
			has_tried_to_move = true
			has_moved = try_move(Directions.UP_LEFT)
		if (not has_moved) and Input.is_action_pressed("move_left"):
			has_tried_to_move = true
			has_moved = try_move(Directions.LEFT)
		if (not has_moved) and Input.is_action_pressed("move_down_left"):
			has_tried_to_move = true
			has_moved = try_move(Directions.DOWN_LEFT)
		if (not has_moved) and Input.is_action_pressed("move_down"):
			has_tried_to_move = true
			has_moved = try_move(Directions.DOWN)
		if (not has_moved) and Input.is_action_pressed("move_down_right"):
			has_tried_to_move = true
			has_moved = try_move(Directions.DOWN_RIGHT)
	
	var has_undoed := false
	if (not has_moved) and Input.is_action_pressed("undo"):
		has_undoed = try_undo()


#  __  __
# |  \/  |
# | \  / | ___  _   _ ___  ___
# | |\/| |/ _ \| | | / __|/ _ \
# | |  | | (_) | |_| \__ \  __/
# |_|  |_|\___/ \__,_|___/\___|
#
#

var __mouse_controls_deadzone := pow(33, 2)
var __is_currently_using_drag_joystick := false
var __mouse_controls_start_position := Vector2.ZERO
var __mouse_controls_pressure_gauge := 0.0

func handle_mouse_inputs(event:InputEventMouse) -> void:
	if (
		event is InputEventMouseButton
		and
		(
			BUTTON_LEFT == event.button_index
			# Undo on right click is handled by an InputMap Action instead
#			or
#			BUTTON_RIGHT == event.button_index
		)
	):
		if event.pressed:
			start_using_drag_joystick(event.position)
		else:
			stop_using_drag_joystick()
#		prints('Using mouse controls: ', __is_currently_using_drag_joystick)


func start_using_drag_joystick(at_position) -> void:
	__is_currently_using_drag_joystick = true
	__mouse_controls_start_position = at_position
	show_mouse_gui()
	move_mouse_gui_at_position(get_global_mouse_position())


func stop_using_drag_joystick() -> void:
	__is_currently_using_drag_joystick = false
	__mouse_controls_start_position = Vector2.ZERO
	hide_mouse_gui()


func is_hovering_undo_button(mouse_position) -> bool:
	# I can't manage to reliably get which node/control is selected by the mouse
	# using Godot's internals, so I crutched it.
	if self.undo_button and self.undo_button.visible:
		var view_size = get_viewport().get_visible_rect().size
		var btn_rect = self.undo_button.get_global_rect()
		if btn_rect.has_point(mouse_position-Vector2(0, view_size.y)):
			return true
	
	return false


func handle_mouse_inputs_on_process(delta) -> void:
	
	if not is_accepting_inputs():
		return
	
	var mouse_position = get_tree().get_root().get_mouse_position()
	
	if is_hovering_undo_button(mouse_position):
		stop_using_drag_joystick()
		return
	
	if __is_currently_using_drag_joystick:
#		Input.is_mouse_button_pressed(BUTTON_LEFT)
		fill_mouse_gui(__mouse_controls_pressure_gauge)
		var direction_vector = mouse_position - __mouse_controls_start_position
		if direction_vector.length_squared() > __mouse_controls_deadzone:
			var direction = Directions.get_direction_from_vector(direction_vector)
			
			add_to_mouse_gui_pressure_gauge(
				-1.618  # negative golden ratio
				*
				mouse_gui_fill_sensitivity
				*
				delta
			)
			fill_mouse_gui(0)
			
			if is_in_limbo():
				release_direction_in_mouse_gui()
				return
			
			mark_direction_in_mouse_gui(direction)
			
			if is_cooling_down_between_actions(-1, 5*(100-AppSettings.get_setting("controls", "dragstick", "speed"))):
				return
			
			var _has_moved = try_move(direction)

		else:
			add_to_mouse_gui_pressure_gauge(
				mouse_gui_fill_sensitivity
				*
				delta
			)
			release_direction_in_mouse_gui()
#			show_mouse_gui_pressure_gauge()
			fill_mouse_gui(__mouse_controls_pressure_gauge)
		
		if __mouse_controls_pressure_gauge >= 1.0:
			__mouse_controls_pressure_gauge = 0.0
			try_pass()
	else:
		add_to_mouse_gui_pressure_gauge(
			-1.62
			*
			mouse_gui_fill_sensitivity
			*
			delta
		)


func add_to_mouse_gui_pressure_gauge(how_much:float) -> void:
	__mouse_controls_pressure_gauge = min(
		1.0,
		max(
			0.0,
			__mouse_controls_pressure_gauge + how_much
		)
	)


#       _                             _
#      | |                           | |
#      | | ___  _   _ _ __   __ _  __| |___
#  _   | |/ _ \| | | | '_ \ / _` |/ _` / __|
# | |__| | (_) | |_| | |_) | (_| | (_| \__ \
#  \____/ \___/ \__, | .__/ \__,_|\__,_|___/
#                __/ | |
#               |___/|_|


var joy_controls_deadzone = 0.7

func handle_joypad_inputs_on_process(delta) -> void:
	
	if not is_accepting_inputs():
		return
	if is_cooling_down_between_actions():
		return
	
	var can_move : bool = not is_in_limbo()
	var has_moved := false
	var has_tried_to_move := false
	
	var joypad_indices := Input.get_connected_joypads()
	
	for joypad_index in joypad_indices:
		if can_move and not has_tried_to_move:
			var direction_vector = Vector2(
				Input.get_joy_axis(joypad_index, JOY_AXIS_0),
				Input.get_joy_axis(joypad_index, JOY_AXIS_1)
			)
			
			if direction_vector.length_squared() > self.joy_controls_deadzone:
				var direction = Directions.get_joystick_direction_from_vector(direction_vector)
				has_tried_to_move = true
				has_moved = try_move(direction)


#               _   _
#     /\       | | (_)
#    /  \   ___| |_ _  ___  _ __  ___
#   / /\ \ / __| __| |/ _ \| '_ \/ __|
#  / ____ \ (__| |_| | (_) | | | \__ \
# /_/    \_\___|\__|_|\___/|_| |_|___/
#
#

var actions_history := Array()  # of Action subclasses like MoveAction
var recorded_solution := ''  # Eg: 6669726649  (numpad controls)


func try_undo() -> bool:
	start_action_cooldown()
	
	## move these to signal listeners?
	hide_arrow_gauge()
	if self.undo_gui_button:
		self.undo_gui_button.rewind()
	##################################
	
	emit_signal("before_action_executed")
	emit_signal("before_action_undoed")
	var action = UndoAction.new()
	self.actions_history.append(action)
	undo()
	emit_signal("after_action_undoed")
	emit_signal("after_action_executed", action)
	return true


func try_pass() -> bool:
	start_action_cooldown()
	emit_signal("before_action_executed")
	emit_signal("before_action_passed")
	var action = PassAction.new()
	self.actions_history.append(action)
	spend_turn()
	perhaps_open_a_portal()
	emit_signal("after_action_passed")
	emit_signal("after_action_executed", action)
	return true


func try_move(direction) -> bool:
	start_action_cooldown()
	emit_signal("before_action_executed")
	emit_signal("before_action_moved", direction)
	var has_moved = try_move_items(get_items_that_are_you(), direction)
	if has_moved['any'] and not self.replay_run:
		# BEFORE spend_turn(), at least until the SoundFx knows how to play concurrent sounds
		SoundFx.play("move_%02d" % [1 + randi() % 4])
	
	var action = MoveAction.new(direction)
	self.actions_history.append(action)
	spend_turn()
	emit_signal("after_action_moved", direction)
	emit_signal("after_action_executed", action)
	return has_moved['any']


func try_move_items(items: Array, direction, dry:=false) -> Dictionary:
	"""
	Moves a batch of items together.
	"""
#	if not items:
#		return 
	
	var any_has_moved := false
	var all_have_moved := true
	var items_that_moved := Array()
	var items_that_did_not_move := Array()
	
	var items_by_direction := Directions.build_directions_index()
	var items_by_direction_and_cell := {
		Directions.RIGHT: Dictionary(),
		Directions.LEFT: Dictionary(),
		Directions.UP_LEFT: Dictionary(),
		Directions.UP_RIGHT: Dictionary(),
		Directions.DOWN_LEFT: Dictionary(),
		Directions.DOWN_RIGHT: Dictionary(),
	}
	for item in items:
		direction = coerce_item_direction(item, direction)
		# Use item.cell_position here later when available
#		var cell = HexagonalLattice.tile_to_cell(item.tile_position)
		var cell = item.cell_position
		
		if not items_by_direction_and_cell[direction].has(cell):
			items_by_direction_and_cell[direction][cell] = Array()
		items_by_direction_and_cell[direction][cell].push_back(item)
	
	for direction in Directions.USED_DIRECTIONS:
		for cell in items_by_direction_and_cell[direction]:
			items_by_direction[direction].append({
				'items': items_by_direction_and_cell[direction][cell],
				'direction_string': direction,
				'cell': cell,
				'direction': Directions.to_cell(direction),
			})
	
	for direction in Directions.USED_DIRECTIONS:
		items_by_direction[direction].sort_custom(HexagonalLattice, "sort_by_direction")
#		items_by_direction[direction].invert()
		
	
	for direction in Directions.USED_DIRECTIONS:
		for items_blob in items_by_direction[direction]:
			for i in range(items_blob['items'].size()-1, -1, -1):
				var item = items_blob['items'][i]
				var that_one_may_move := try_move_item(item, direction, true)
				if that_one_may_move:
					any_has_moved = true  # hmmm we redo this below
					items_that_moved.push_back(item)
				else:
					if item.is_weak and not dry:
						item.pretend_to_move(direction)
						destroy_item(item)
						items_blob['items'].remove(i)
					else:
						all_have_moved = false
						items_that_did_not_move.push_back(item)
	
	if not dry:
		# We're moving only the first item of each tile.
		# The remaining items (if any) are moved without checks,
		# nor any PULL or PUSH logic.
		# This allows piled items that are STOP to move together.
		for direction in Directions.USED_DIRECTIONS:
			for items_blob in items_by_direction[direction]:
				var is_first := true
				var has_succeeded_once := false
				for item in items_blob['items']:
					var that_one_moved := false
					if not has_succeeded_once:
						that_one_moved = try_move_item(item, direction, false)
						if that_one_moved:
							has_succeeded_once = true
					else:
						var next_cell := HexagonalLattice.find_adjacent_cell_position(
							item.cell_position,
							direction
						)
						do_move_item(item, next_cell, direction)
					
					if that_one_moved:
						any_has_moved = true
	
	return {
		'any': any_has_moved,
		'all': all_have_moved,
		'items_that_moved': items_that_moved,
		'items_that_did_not_move': items_that_did_not_move,
#		'items_that_were_destroyed': items_that_were_destroyed,
	}


func try_move_item(item, direction, dry:=false) -> bool:
	direction = coerce_item_direction(item, direction)
	
	# Ok, let's look at what we have on the target tile
	var starting_cell = item.cell_position
	var next_tile := HexagonalLattice.find_adjacent_tile_position(
		item.tile_position,
		direction
	)
	var next_cell := HexagonalLattice.cell_from_tile(next_tile)
	
	# To simplify things, the YOU can only go where there are tiles on the map
	# This differs from BiY, but it keeps things simple and sparse.
	if not can_go_on_tile(next_tile):
		return false
	
	var next_items := get_items_on(next_cell)
	for next_item in next_items:
		assert(next_item != item)
	
	# Rule: STOP items block movement but only if they're not also PUSH
	for next_item in next_items:
		assert(next_item != item)
		if next_item.is_stop and not next_item.is_push:
			return false
	
	# Rule: SHUT items block movement, unless you're OPEN
	for next_item in next_items:
		if not next_item.is_push and next_item.is_shut and not item.is_open:
			return false
	
	# Check if there's room to push
	var found_items_to_push := false
	var items_to_push := Array()
	for next_item in next_items:
#		if next_item.is_pushable():  todo?
		if next_item.is_push or next_item.is_text:
			found_items_to_push = true
			items_to_push.push_back(next_item)
	
	if items_to_push:
		var can_next_move = try_move_items(items_to_push, direction, true)
		if not can_next_move['all']:
			return false
	
	# Apply push movement on the items on the next tile
	if items_to_push and not dry:
		try_move_items(items_to_push, direction, false)
	
	# Apply move to this item
	if not dry:
		do_move_item(item, next_cell, direction)
	
	# Apply PULL to items behind
	if not dry:
		var cell_behind = HexagonalLattice.find_adjacent_cell_position(
			starting_cell,
			Directions.inverse(direction)
		)
		var items_behind = get_items_on(cell_behind)
		var items_to_pull := Array()
		for item_behind in items_behind:
#			if not item_behind.is_pullable():  # todo?
			if not item_behind.is_pull:
				continue
			items_to_pull.append(item_behind)
		if items_to_pull:
			var _can_prev_move = try_move_items(items_to_pull, direction, false)
	
	return true


func do_move_item(item, next_cell, direction):
	#item.cell_position = next_cell  # someday
	item.tile_position = HexagonalLattice.tile_from_cell(next_cell)
	if item.direction != direction:
		item.direction = direction
	item.advance_animation()
	item.update_sprite(false)
	item.raise_dust()
	item.reposition(false)


################################################################################
# This coercition logic should go elsewhere

func coerce_item_direction(item, direction):
	return coerce_item_direction_to_hexagon(item, direction)

func coerce_item_direction_to_hexagon(item, direction):
	# Shenanigans to support UP and DOWN
	if direction == Directions.UP:
		if item.is_looking_right():
			direction = Directions.UP_RIGHT
		else:
			direction = Directions.UP_LEFT
	if direction == Directions.DOWN:
		if item.is_looking_right():
			direction = Directions.DOWN_RIGHT
		else:
			direction = Directions.DOWN_LEFT
	
	return direction


################################################################################

func get_items_from_scene() -> Array:
	var items := Array()
	var items_layer_noready = find_node('Items')
	for item in items_layer_noready.get_children():
#	for item in self.items_layer.get_children():
		if item is Item and item.is_on_lattice():
			items.append(item)
	return items


func reindex_lattice() -> void:
	self.cell_lattice.reindex_from_nodes(
		get_items_from_scene()
	)



#  _      _           _
# | |    (_)         | |
# | |     _ _ __ ___ | |__   ___
# | |    | | '_ ` _ \| '_ \ / _ \
# | |____| | | | | | | |_) | (_) |
# |______|_|_| |_| |_|_.__/ \___/
#
#

signal limbo_entered
signal limbo_exited

var __is_in_limbo := false


func is_in_limbo() -> bool:
	return self.__is_in_limbo


func update_limbo_status():
	if is_editor_preview():
		return
	
	var no_you = true
	for item in get_all_items():
		if item.is_you:
			no_you = false
			break
	if no_you:
		enter_limbo()
	else:
		exit_limbo()


func enter_limbo():
	if not is_in_limbo():
		self.modulate = Color(0.8, 0.8, 0.8, 1.0)
		#self.animation_player.play("EnterLimbo")
		self.__is_in_limbo = true
		emit_signal("limbo_entered")
		mouse_gui.show_right_mouse_button_hint()  # use signal instead


func exit_limbo():
	if is_in_limbo():
		self.modulate = Color(1.0, 1.0, 1.0, 1.0)
		#self.animation_player.play_backwards("EnterLimbo")
		self.__is_in_limbo = false
		emit_signal("limbo_exited")
		mouse_gui.hide_mouse_button_hint()  # use signal instead


#  _____       _
# |  __ \     | |
# | |__) |   _| | ___  ___
# |  _  / | | | |/ _ \/ __|
# | | \ \ |_| | |  __/\__ \
# |_|  \_\__,_|_|\___||___/
#
#

signal turn_spending_started
signal turn_spending_ended
# TBD signal turn_started, why `spending`?


func can_go_on_tile(that_tile: Vector2) -> bool:
	var map = get_tile_map()
	if not map:
		return false
	var is_emptiness = (map.get_cellv(that_tile) == map.INVALID_CELL)
	# … add more emptiness conditions here as-needed
	return not is_emptiness


#func compute_turn(): who cares how it is named?
func spend_turn(in_editor := false):
	
	# move this into a signal listener? -- requires the hint to know about the level
	if self.undo_gui_button and not in_editor:
		self.undo_gui_button.advance()
	#########

	emit_signal("turn_spending_started")

	# For faster computation later, we want to index the items.
	# Here's an easy but expensive place to reindex.
	# We should probably (re-)index at the END of the turn, or use signals
	reindex_lattice()
	
	# VII. MOVE
	if not in_editor:
		apply_move_effect()
		# Urgh. Let's try to keep track while moving please
		reindex_lattice()
	
	# I. Reset qualities and stuff, sentences will be re-applied
	reset_qualities_and_stuff()
	
	# II. Find all the possible sentences
	var sentences = get_possible_sentences()
	
	# II.d Log things
	var msg_log = "Turn %03d" % [history.size()]
	if not sentences.empty():
		msg_log += ' — '
		for i in range(sentences.size()):
			var sentence = sentences[i]
			if i > 0:
				msg_log += ', '
			msg_log += sentence.to_pretty_string()
	if not self.is_dummy_run():
		print(msg_log)

	# IV. Apply sentences
	for item in get_all_items():
		apply_qualifying_sentences_to_item(sentences, item)
	if not in_editor:
		for item in get_all_items():
			apply_stuffing_sentences_to_item(sentences, item)
		for item in get_all_items():
			apply_alchemical_sentences_to_item(sentences, item)
		for item in get_all_items():
			apply_maker_sentences_to_item(sentences, item)
			
		for item in get_all_items():  # another stuffin pass, for created items
			apply_stuffing_sentences_to_item(sentences, item)
		for item in get_all_items():  # another qualifying pass, for created items?
			apply_qualifying_sentences_to_item(sentences, item)
	
	# II.c Light up the words of the sentences
	for sentence in sentences:
		for item in sentence.items_used:
			item.is_lit = true
		
	# III. Identity (THING IS THING) has utmost priority
	var things_locked = get_things_locked_to_identity(sentences)
	for sentence_object in sentences:
		if Words.VERB_IS != sentence_object.verb.concept_name:
			continue
		var locked_subjects = Array()
		var locked_subjects_concepts = Array()
		for subject in sentence_object.subjects:
			if things_locked.has(subject.concept_name) and not subject.negated:
				locked_subjects.append(subject)
				locked_subjects_concepts.append(subject.concept_name)
		if not locked_subjects:
			continue
		var locked_complements = Array()
		for complement in sentence_object.complements:
			if not complement.is_thing:
				continue
			if complement.negated:
				continue
			if locked_subjects_concepts.has(complement.concept_name):
				continue
			locked_complements.append(complement)
		if not locked_complements:
			continue
		# TODO: partial lock?
		if locked_complements.size() == sentence_object.complements.size():
			if locked_subjects.size() == sentence_object.subjects.size():
				for item in sentence_object.items_used:
					item.is_ignored = true
	
	
	# VIII. Same-tile effects
	var has_won = false
	if not in_editor:
		apply_weak_effect()
		apply_void_effect()
		apply_sink_effect()
		apply_hot_effect()
		apply_poet_effect()
		apply_more_effect(sentences)
		
		apply_qualifying_sentences(sentences)
		has_won = apply_win_effect()
		if not has_won:
			apply_defeat_effect()
			apply_open_effect()

	# more special cases
	# …

	# XX. Defeat|Limbo Scenario : THERE IS NO YOU
	if not in_editor and not has_won:
		update_limbo_status()
#		var no_you = true
#		for item in get_all_items():
#			if item.is_you:
#				no_you = false
#				break
#		if no_you:
#			enter_limbo()
#		else:
#			exit_limbo()

	# Reposition all the items?
	# …?

	# Update the items aesthetics from their new flags
	for item in get_all_items():
#		item.update_aesthetics()
		item.update_particles()
#		item.update_z_salience()

	# L. Reregister all the items in case we created some.
	# This could be optimized, if necessary, by registering only when needed.
	register_all_items()

	# LI. Write this turn into the history ledger
	write_history()
	
	# LII. Hidden, discoverable content is the best content
	perhaps_trigger_achievements_on_turn()
	
	# C. Emit signals !
	emit_signal("turn_spending_ended")
	
	# Meanwhile…
	update_portal_selection()
	#update_items_z_salience()


#                       _          _____            _
#     /\               | |        / ____|          | |
#    /  \   _ __  _ __ | |_   _  | (___   ___ _ __ | |_ ___ _ __   ___ ___
#   / /\ \ | '_ \| '_ \| | | | |  \___ \ / _ \ '_ \| __/ _ \ '_ \ / __/ _ \
#  / ____ \| |_) | |_) | | |_| |  ____) |  __/ | | | ||  __/ | | | (_|  __/
# /_/    \_\ .__/| .__/|_|\__, | |_____/ \___|_| |_|\__\___|_| |_|\___\___|
#          | |   | |       __/ |
#          |_|   |_|      |___/


func apply_qualifying_sentences(sentences: Array) -> void:
	for item in get_all_items():
		apply_qualifying_sentences_to_item(sentences, item)


func apply_qualifying_sentences_to_item(sentences:Array, item:Item) -> void:
	"""
	This does not apply the effects of qualities.
	It sets the qualities flags of the item to the correct value.
	"""
	item.reset_qualities()
	
	var applicable_sentences = get_applicable_sentences(sentences, item)
	var qualities_to_acquire := Array()
	var qualities_to_not_acquire := Array()
	
	for sentence in applicable_sentences:
		if not sentence.verb.is_word(Words.VERB_IS):
			continue
		for complement in sentence.complements:
			if complement.is_quality:
				if complement.negated:
					if not qualities_to_not_acquire.has(complement.concept_name):
						qualities_to_not_acquire.append(complement.concept_name)
				else:
					if not qualities_to_acquire.has(complement.concept_name):
						qualities_to_acquire.append(complement.concept_name)
	
	for quality in qualities_to_acquire:
		if not qualities_to_not_acquire.has(quality):
			item.qualify(quality)


func apply_alchemical_sentences_to_item(sentences:Array, item:Item) -> void:
	var applicable_sentences := get_applicable_sentences(sentences, item)
	var is_item_locked_to_identity := false
	
	for sentence in applicable_sentences:
		if not sentence.verb.is_word(Words.VERB_IS):
			continue
		for complement in sentence.complements:
			if not complement.is_thing:
				continue
			if complement.negated:
				continue
			if complement.concept_name == item.concept_name:
				is_item_locked_to_identity = true
	
	if is_item_locked_to_identity:
		return
	
	for sentence in applicable_sentences:
		if not sentence.verb.is_word(Words.VERB_IS):
			continue
		var things_to_become := Array()  # of concepts names
		for complement in sentence.complements:
			if complement.is_thing:
				if complement.negated:
					for other_thing in __unique_nouns_available:
						if other_thing == complement.concept_name:
							continue
						things_to_become.append(other_thing)
				else:
					things_to_become.append(complement.concept_name)
		
		if things_to_become:
			item.transmute(things_to_become.pop_front())
		if things_to_become:
			for thing_to_become in things_to_become:
				var created_item = spawn_item(item, {
					'concept_name': thing_to_become,
				})


func apply_stuffing_sentences_to_item(sentences:Array, item:Item) -> void:
	item.reset_stuffing()
	var applicable_sentences = get_applicable_sentences(sentences, item)
	for sentence in applicable_sentences:
		if not sentence.verb.is_word(Words.VERB_HAS):
			continue
		for complement in sentence.complements:
			# fixme: handle complement.negated around here  THING HAS NOT THING
			if complement.is_thing:
#				debug("Stuffing `%s' (%s) with `%s'." % [
#					item.concept_name,
#					hash_item(item),
#					complement.concept_name,
#				])
				item.stuff_with(complement.concept_name)


func apply_maker_sentences_to_item(sentences:Array, item:Item) -> void:
	if item.is_text:
		return
	var applicable_sentences := get_applicable_sentences(sentences, item)
	if not applicable_sentences:
		return
	var other_things_on_cell := get_things_piled_with(item, false)
	var concepts_of_things_already_on_cell := [
		item.concept_name,
	]
	for other_thing in other_things_on_cell:
		var other_thing_concept = other_thing.concept_name
		if not concepts_of_things_already_on_cell.has(other_thing_concept):
			concepts_of_things_already_on_cell.append(other_thing_concept)
	
	for sentence in applicable_sentences:
		if not sentence.verb.is_word(Words.VERB_MAKE):
			continue
		var concepts_of_things_to_add := Array()  # of concept Strings
		for complement in sentence.complements:
			if not complement.is_thing:
				continue  # Rule: THING MAKE QUALITY means … what?
			
			# KISS: ignore quantifiers (for now)
			
			if complement.negated:
				for concept_name in self.__unique_nouns_available:
					if concept_name == complement.concept_name:
						continue
					concepts_of_things_to_add.append(concept_name)
			else:
				concepts_of_things_to_add.append(complement.concept_name)
		
		for concept_name in concepts_of_things_to_add:
			if concept_name in concepts_of_things_already_on_cell:
				continue
			var spawned_item = spawn_item(item, {
				'concept_name': concept_name,
			})
			spawned_item.animate_spawn(
				get_action_cooldown() * 0.95
			)


#   _____            _
#  / ____|          | |
# | (___   ___ _ __ | |_ ___ _ __   ___ ___  ___
#  \___ \ / _ \ '_ \| __/ _ \ '_ \ / __/ _ \/ __|
#  ____) |  __/ | | | ||  __/ | | | (_|  __/\__ \
# |_____/ \___|_| |_|\__\___|_| |_|\___\___||___/
#
#

func get_possible_sentences() -> Array:
	
	# Find all the possible sentences
	# VERLAN = COMPLEMENTS VERB SUBJECTS  (reversed) sentences
	var sentences = get_possible_sentences_directed(false)
	var verlan_sentences = get_possible_sentences_directed(true)
	
	var sentences_setting_verlan := Array()
	var verlan_concepts := Array()
	for sentence in (sentences+verlan_sentences):
		if sentence.has_complement_quality(Words.QUALITY_YODA):
			sentences_setting_verlan.append(sentence)
			for subject in sentence.subjects:
				verlan_concepts.append(subject.concept_name)
	
	if not verlan_concepts:
		return sentences
	
	var applicable_verlan_sentences := Array()
	
	for sentence in verlan_sentences:
		var found = false
		for concept in verlan_concepts:
			if not sentence.uses_concept(concept):
				continue
			found = true
			break
		if not found:
			continue
		applicable_verlan_sentences.append(sentence)
	
	var verlan_adjusted_sentences := Array()
	for sentence in sentences:
		if (
			sentence.uses_any_concept(verlan_concepts)
		):
			continue  # verlan also disables LeftToRight sentence order
		verlan_adjusted_sentences.append(sentence)
	
	if applicable_verlan_sentences:
		for sentence in applicable_verlan_sentences:
			verlan_adjusted_sentences.append(sentence)
		
	for sentence in sentences_setting_verlan:
		if verlan_adjusted_sentences.has(sentence):
			continue
		verlan_adjusted_sentences.append(sentence)
	
	sentences = verlan_adjusted_sentences
	
	return sentences


func get_possible_sentences_directed(verlan:=false) -> Array:
	var possible_sentences := Array()
	var items = get_text_items()
	for item in items:
		var sentences = get_possible_sentences_from(item.cell_position, verlan)
		possible_sentences = possible_sentences + sentences
	
	# Filter out sentences fully contained in bigger sentences
	# This will not work cross-verlan as is /!.
	for i in range(possible_sentences.size()-1, -1, -1):
		var sentence_inspected = possible_sentences[i]
		for j in range(possible_sentences.size()-1, -1, -1):
			var other_sentence = possible_sentences[j]
			if sentence_inspected == other_sentence:
				continue
			if other_sentence.contains_sentence(sentence_inspected):
				possible_sentences.remove(i)
				break
	
	return possible_sentences


func get_possible_sentences_from(from_cell: Vector2, verlan := false) -> Array:
	
	if verlan:
		return (
			get_possible_sentences_in_direction(from_cell, Directions.LEFT)
			+
			get_possible_sentences_in_direction(from_cell, Directions.UP_LEFT)
		)
	
	return (
		get_possible_sentences_in_direction(from_cell, Directions.RIGHT)
		+
		get_possible_sentences_in_direction(from_cell, Directions.DOWN_RIGHT)
	)


func get_possible_sentences_in_direction(from_cell: Vector2, direction) -> Array:
	var items := Array()
	var sentences := Array()
	var current_cell := from_cell
	
	for item in self.cell_lattice.find_at(current_cell):
		if not item.is_text:
			continue
		sentences.append([item])
	
	if sentences.empty():
		return sentences
	
	# Each cell may have multiple text items on it,
	# and we want all the combinations → tree flattening
	var there_is_more := true
	while there_is_more:
		var previous_cell = current_cell
		current_cell = self.cell_lattice.find_adjacent_cell_position(
			current_cell, direction
		)
		assert(current_cell != previous_cell)
		items = self.cell_lattice.find_at(current_cell)
		there_is_more = false
		var new_sentences := Array()
		for item in items:
			if not item.is_text:
				continue
			there_is_more = true
			for sentence in sentences:
				new_sentences.append(sentence + [item])
		if there_is_more:
			sentences = new_sentences
	
	# Prune sentences of less than three words
	for i in range(sentences.size()-1, -1, -1):
		if 3 > sentences[i].size():
			sentences.remove(i)
	
	# Keep only valid sentences
	var sentences_as_objects := Array()
	for sentence in sentences:
		var sentence_as_object := Sentence.new()
		sentence_as_object.from_items(sentence)
		if sentence_as_object.is_valid:
			sentences_as_objects.append(sentence_as_object)
	
	return sentences_as_objects


func get_applicable_sentences(sentences: Array, item: Item) -> Array:
	"""
	Gets all sentences where item matches a subject.
	"""
	var applicable_sentences := Array()
	for sentence in sentences:
		var is_a_subject := false
		
		for subject in sentence.subjects:
			var ignore_quantifier := true  # KISS
			if is_item_matching_subject(item, subject, ignore_quantifier):
				is_a_subject = true
				break
		
		if not is_a_subject:
			continue
		
		applicable_sentences.append(sentence)
	
	return applicable_sentences


func get_things_locked_to_identity(sentences:Array) -> Array:
	var is_item_locked_to_identity := false
	var concepts_locked := Array()
	
	for sentence in sentences:
		if Words.VERB_IS != sentence.verb.concept_name:
			continue
		for subject in sentence.subjects:
			if not subject.is_thing:
				assert(false, "Wait…  What?  No!")
				continue
			if subject.negated:
				continue
			for complement in sentence.complements:
				if not complement.is_thing:
					continue
				if complement.negated:
					continue
				if complement.concept_name == subject.concept_name:
					concepts_locked.append(subject.concept_name)
	
	return concepts_locked


################################################################################

#  _____                               _
# |  __ \                             | |
# | |__) |___ _ __ ___   ___ _ __ ___ | |__  _ __ __ _ _ __   ___ ___
# |  _  // _ \ '_ ` _ \ / _ \ '_ ` _ \| '_ \| '__/ _` | '_ \ / __/ _ \
# | | \ \  __/ | | | | |  __/ | | | | | |_) | | | (_| | | | | (_|  __/
# |_|  \_\___|_| |_| |_|\___|_| |_| |_|_.__/|_|  \__,_|_| |_|\___\___|
#
# 

# All the Items (including the "destroyed" ones) that at some point
# appeared in the level are indexed here.
# We use this to fetch past Items during undo for example.
# This will also keep the past Items safe from garbage collection,
# once they are removed from the scene tree.
# 
# TODO
# ----
# We may end up with extra, orphaned items in here.
# Upon UNDO for example, we could check each item in here
# to see if it is still in history, and remove it if not.
var items_bag := Dictionary()  # instance_id => Item


# The history of turns spent on this level.
# Undo truncates the last entry.
# We could use this upon victory to show a replay, that would be awesome.
var history := Array()  # of Dictionary(instance_id => item_pickle)


func hash_item(item):
	return item.get_instance_id()


func deregister_all_items():
	self.items_bag.clear()


func register_all_items():
	for item in get_items_from_scene():
		register_item(item)


func register_item(item):
	assert(item is Item)
	var key = hash_item(item)
	if key in self.items_bag:
		assert(item == self.items_bag[key])
		return
	self.items_bag[key] = item


func write_history():
	if self.history.size() == 0:  # waiting for Dictionary.is_empty() to exist
		self.initial_pickle = to_pickle()
	
	var this_turn := Dictionary()
	for item in get_all_items():
		this_turn[hash_item(item)] = item.to_pickle()
	self.history.append(this_turn)
#	self.history.append(to_pickle())  # nope, we want an item hash


func undo():
	if 2 > self.history.size():
		return
	seek_to_history(-2)
	#update_limbo_status()
	#call_deferred('__deferred_undo')


#func __deferred_undo():
#
#	for item in get_all_items():
#		self.items_layer.remove_child(item)
#
#	var previous_turn = self.history[self.history.size() - 2]
#	for item_hash in previous_turn.keys():
#		assert(item_hash in self.items_bag)
#		var item = self.items_bag[item_hash]
#		item.from_pickle(previous_turn[item_hash])
#		self.items_layer.add_child(item)
#		item.reposition()
#		item.update_aesthetics()
#
#	self.history.pop_back()
#
#	reindex_lattice()
#
#	#perhaps_exit_limbo()
#	exit_limbo()
#	update_portal_selection()


func seek_to_history(turn: int):
	"""
	turn:
		Index of the turn (starts at 0), negative numbers are looped.
		Note:
			turn ==  0 means the initial state before the first turn.
			turn ==  1 means after the first turn.
			turn == -1 means the current turn.
			turn == -2 means the previous turn.
	"""
	if turn < 0:
		turn = self.history.size() + turn
	if turn >= self.history.size():
		breakpoint
		return
	call_deferred('__seek_to_history', turn)


func __seek_to_history(turn: int):
	assert(turn >= 0)
	assert(turn < self.history.size())
	
	for item in get_all_items():
		self.items_layer.remove_child(item)
	
	var turn_data = self.history[turn]
	for item_hash in turn_data.keys():
		assert(item_hash in self.items_bag)
		var item = self.items_bag[item_hash]
		if item is Portal:
			breakpoint
		item.from_pickle(turn_data[item_hash])
		self.items_layer.add_child(item)
		item.reposition()
		item.update_aesthetics()

	self.history = self.history.slice(0, turn)
	
	reindex_lattice()
	
	update_limbo_status()
	update_portal_selection()


#  _____           _        _
# |  __ \         | |      | |
# | |__) |__  _ __| |_ __ _| |___
# |  ___/ _ \| '__| __/ _` | / __|
# | |  | (_) | |  | || (_| | \__ \
# |_|   \___/|_|   \__\__,_|_|___/
#
#

const Portal = preload("res://addons/laec-is-you/entity/Portal.gd")


onready var portal_selection_hint = find_node('PortalSelectionHint')


var __currently_selected_portal


func get_portals() -> Array:
	return get_all_portals()


func get_all_portals() -> Array:
	var portals := Array()
	for item in get_items_lattice().get_things():
		assert(item is Item)
		assert(item.is_on_lattice())
		if (item is Portal) and item.is_on_lattice():
			portals.append(item)
	return portals


func perhaps_open_a_portal() -> void:
	var portal = get_selected_portal()
	if portal:
		portal.perhaps_open()


func get_selected_portals() -> Array:
	var selected_portals := Array()
	for portal in get_all_portals():
		var piled_with_portal := get_items_piled_with(portal, false)
		for item in piled_with_portal:
			if item.is_you:
				selected_portals.append(portal)
	return selected_portals


func get_selected_portal():
	var selected_portals := get_selected_portals()
	if selected_portals:
		for portal in selected_portals:
			if portal.is_available():
				return portal
	return null


func update_portal_selection() -> void:
	var selected_portal = get_selected_portal()
	if __currently_selected_portal != selected_portal:
		__currently_selected_portal = selected_portal
		if selected_portal:
			self.portal_selection_hint.copy_from_portal(selected_portal)
			self.portal_selection_hint.show()
		else:
			self.portal_selection_hint.hide()


#  _____ _
# |_   _| |
#   | | | |_ ___ _ __ ___  ___
#   | | | __/ _ \ '_ ` _ \/ __|
#  _| |_| ||  __/ | | | | \__ \
# |_____|\__\___|_| |_| |_|___/
#
#


func spawn_item(item_to_copy=null, extra_properties:Dictionary={}):
	"""
	Creates a new Item instance and adds it to the scene tree.
	This may also emit some signals in the future.
	
	item_to_copy:
		Another Item to copy from, if provided.
		Has no type set (Item) in the definition above
		because of cyclic failures with class_name.
	extra_properties:
		Takes the form of a pickled item, basically.
		Has priority over the item to copy and defaults.
	"""
	var items_layer = self.items_layer
	if not items_layer:
		printerr("No items layer into which spawn an Item.")
		breakpoint
		return
	var item = ItemScene.instance()
	if item_to_copy:
		item.copy_from_item(item_to_copy)
	
	for prop in extra_properties:
		item.set(prop, extra_properties[prop])
	
	items_layer.add_child(item)
	item.set_owner(items_layer.get_owner())
	cell_lattice.add_thing_on_cell(item, item.cell_position)
	
	# and emit a signal (todo)
	
	return item


func get_unique_nouns_available() -> Array:  # of String concepts
	var unique_things := Array()
	for concept in get_unique_concepts_available():
		if not Words.is_noun(concept):
			continue
		unique_things.append(concept)
	return unique_things


func get_unique_concepts_available() -> Array:  # of String concepts
	var unique_concepts := Array()
	for item in get_all_items():
		var concept = item.get_concept_name()
		if unique_concepts.has(concept):
			continue
		unique_concepts.append(concept)
	#print(unique_concepts)
	return unique_concepts


func get_things(thing_name=null, is_text=null):
	var things := Array()
	for item in get_all_items():
		if item.is_thing:
			if null != thing_name and item.concept_name != thing_name:
				continue
			if null != is_text and item.is_text != is_text:
				continue
			things.append(item)
	return things


func is_item_matching_subject(
		item,
		subject: Subject,
		ignore_quantifier := false
) -> bool:
	assert(ignore_quantifier, "Not implemented :(|) What would it even mean?")
	
	if item.is_text:
		return false  # KISS (TEXT, here?)
	
	var matches_concept := false
	if subject.negated:
		matches_concept = (subject.concept_name != item.concept_name)
	else:
		matches_concept = (subject.concept_name == item.concept_name)
	
	# quick 'n dirty → refactor to use one class per word
	var matches_epithets := true
	if subject.has_epithet(Words.EPITHET_PREFIX_LONELY):
		var is_item_lonely := get_items_piled_with(item).size() > 0
		if subject.prefix_negated:
#		if subject.has_epithet_negated(Words.EPITHET_PREFIX_LONELY):
			matches_epithets = is_item_lonely
		else:
			matches_epithets = not is_item_lonely
	
	var matches_attributes := true
	for attribute in subject.attributes:
		var matches_attribute := false
		
		#              _
		#             | |
		#  _   _  ___ | | ___
		# | | | |/ _ \| |/ _ \
		# | |_| | (_) | | (_) |
		#  \__, |\___/|_|\___/
		#   __/ |
		#  |___/
		# 
		#class PrepositionOn:
		#	extends 
		#	func is_matching(item, attribute: Attribute) -> bool:
		
		
		if attribute.preposition == Words.PREPOSITION_ON:
			var found_thing_on_tile := false
			for piled_thing in get_things_piled_with(item):
				if piled_thing.is_real_thing(attribute.noun, attribute.noun_negated):
					found_thing_on_tile = true
					break
			
			if attribute.preposition_negated:
				matches_attribute = not found_thing_on_tile
			else:
				matches_attribute = found_thing_on_tile
		
		elif attribute.preposition == Words.PREPOSITION_WITH:
			var found_companion_in_level := false
			for level_thing in get_things():
				if level_thing.is_real_thing(attribute.noun, attribute.noun_negated):
					found_companion_in_level = true
					break
			
			if attribute.preposition_negated:
				matches_attribute = not found_companion_in_level
			else:
				matches_attribute = found_companion_in_level
		
#		elif attribute.preposition == Words.PREPOSITION_FACING:
#			pass
		
		else:
			breakpoint  # unrecognized preposition !
			continue
		
		if not matches_attribute:
			matches_attributes = false
			break
	
	var matches_subject = (
		matches_epithets
		and
		matches_concept
		and
		matches_attributes
	)
	
	# Can/should we negate matches_subject somehow?
	# If not, we can optimize by using additional return statements.
	
	return matches_subject


func get_things_matching_subject(subject:Subject, ignore_quantifier:=false) -> Array:
	var matching_items := Array()
	var matching_items_per_cell := Dictionary()
	
	for item in get_all_items():
		var matches_subject = is_item_matching_subject(
			item, subject, true
		)
		
		if matches_subject:
			var cell = item.cell_position
			if not matching_items_per_cell.has(cell):
				matching_items_per_cell[cell] = Array()
			matching_items_per_cell[cell].append(item)
			matching_items.append(item)
	
	if not ignore_quantifier:
		matching_items.clear()
		for cell in matching_items_per_cell:
			var amount_of_items_on_cell = matching_items_per_cell[cell].size()
			
			var matching_amount = amount_of_items_on_cell >= subject.quantifier.amount
			if subject.quantifier.negated:
				matching_amount = amount_of_items_on_cell < subject.quantifier.amount
			if matching_amount:
				matching_items += matching_items_per_cell[cell]
	
	return matching_items


func get_all_items() -> Array:
	var items := Array()
	# We used to get these from the scene tree but it's slow
#	for item in self.items_layer.get_children():
	for item in get_items_lattice().get_things():
		assert(item is Item)
		assert(item.is_on_lattice())
		if item is Portal:
			continue
		if item is Item and item.is_on_lattice():
			items.append(item)
	return items


func get_all_items_and_portals() -> Array:
	var items := Array()
	for item in get_items_lattice().get_things():
		assert(item is Item)
		assert(item.is_on_lattice())
		if item is Item and item.is_on_lattice():
			items.append(item)
	return items


func get_items_on(that_cell_position:Vector2) -> Array:
	var items := get_all_items()
	var found_items := Array()
	for item in items:
		if item.cell_position == that_cell_position:
			found_items.append(item)
	return found_items


func get_specific_things_with_qualities(concept, qualities_filter:Dictionary) -> Array:
	#breakpoint  # are we used? (yes core/Condition.gd:95)
	var specific_things := Array()
	var things = get_things_with_qualities(qualities_filter)
	for thing in things:
		if thing.concept_name == concept:
			specific_things.append(thing)
	return specific_things


func get_things_with_qualities(qualities_filter:Dictionary) -> Array:
	qualities_filter['text'] = false
	return get_items_with_qualities(qualities_filter)


func get_items_with_qualities(qualities_filter:Dictionary) -> Array:
	var items := Array()
	for item in get_all_items():
		var validates_filter := true
		for quality in qualities_filter.keys():
			var expected_value = qualities_filter[quality]
			if item.get("is_%s" % [quality]) != expected_value:
				validates_filter = false
				break
		if validates_filter:
			items.append(item)
	return items


func get_text_items() -> Array:
	var text_items := Array()
	for item in get_all_items():
		if item.is_text:
			text_items.append(item)
	return text_items


func get_items_that_are_you() -> Array:
	var you_items := Array()
	for item in get_all_items():
		if item.is_you:
			you_items.append(item)
	return you_items


func get_items_piled_with(item, including_item:=false) -> Array:
	var piled_items := Array()
	for cell_item in self.cell_lattice.find_on_cell(item.cell_position):
		if (not including_item) and (cell_item == item):
			continue
		piled_items.append(cell_item)
	return piled_items


# Note: item is never included if it's not a thing
func get_things_piled_with(item, including_item:=false) -> Array:
	var piled_things := Array()
	for piled_item in get_items_piled_with(item, including_item):
		#if item.is_noun and not item.is_text:
		if piled_item.is_thing and not piled_item.is_text:
			piled_things.append(piled_item)
	return piled_things



# __      ___      _
# \ \    / (_)    | |
#  \ \  / / _  ___| |_ ___  _ __ _   _
#   \ \/ / | |/ __| __/ _ \| '__| | | |
#    \  /  | | (__| || (_) | |  | |_| |
#     \/   |_|\___|\__\___/|_|   \__, |
#                                 __/ |
#                                |___/


const LevelCompleteParticles = preload("res://effects/LevelCompleteParticles.tscn")


# Completion flag for this instance of the scene, not from save.
# This is mostly used by the test suite for orchastration,
# and it is set at the same time the signal is emitted.
var __is_completed := false


func set_completed(completion_status: bool) -> void:
	self.__is_completed = completion_status


func is_completed() -> bool:
	return self.__is_completed


func animate_victory(on_cells: Array) -> void:
	stop_accepting_inputs()
	
	# Particles, yummy particles
	var cpu_irrespect_threshold := 16
	var amount_of_emitters_created := 0
	for cell in on_cells:
		if amount_of_emitters_created > cpu_irrespect_threshold:
			break
		
		var particles = LevelCompleteParticles.instance()
		effects_layer.add_child(particles)
		particles.position = get_tile_map().map_to_world(
			self.cell_lattice.tile_from_cell(cell)
		)
		particles.restart()
		
		amount_of_emitters_created += 1


# __          ___
# \ \        / (_)
#  \ \  /\  / / _ _ __
#   \ \/  \/ / | | '_ \
#    \  /\  /  | | | | |
#     \/  \/   |_|_| |_|
#
# If something that is YOU is piled with something that is WIN,
# the level is completed and the player wins !  \o/
#

func apply_win_effect() -> bool:
	var has_won := false
	var winning_cells := Array()
	var cells = self.cell_lattice.get_used_cells()
	for cell in cells:
		var items_piled = self.cell_lattice.find_on_cell(cell)
		var found_win := false
		var found_you := false
		for item in items_piled:
			if item.is_win:
				found_win = true
			if item.is_you:
				found_you = true
		if found_win and found_you:
			has_won = true
			winning_cells.append(cell)

	if has_won:
		do_win(winning_cells)
	
	return has_won


func do_win(winning_cells: Array):
	stop_level_chronometer()
	self.recorded_solution = get_replay_string()
	
	if not is_dummy_run():
		print("GRATULO !   %s IS WIN" % [self.name.to_upper()])
		print("Replay (solution): %s" % [self.recorded_solution])
		Game.register_victory(self)
	
	animate_victory(winning_cells)
	set_completed(true)
	emit_signal("level_completed", self, winning_cells)
	perhaps_trigger_achievements_on_victory()
	
	if not is_dummy_run():
		SoundFx.play("fanfare")
	
	if has_no_victory_screen():
		if self.forward_level_path:
			yield(get_tree().create_timer(2.0), "timeout")
			go_forward()
		else:
			breakpoint  # you're missing a forward_level_path, probably
	elif not is_dummy_run():
		yield(get_tree().create_timer(2.0), "timeout")
		Game.go_to_level_victory_screen(self)


#  _____        __           _
# |  __ \      / _|         | |
# | |  | | ___| |_ ___  __ _| |_
# | |  | |/ _ \  _/ _ \/ _` | __|
# | |__| |  __/ ||  __/ (_| | |_
# |_____/ \___|_| \___|\__,_|\__|
#
# If something that is You is piled with something that is Defeat,
# the You thing is destroyed and the Defeat thing stays intact.
#

func apply_defeat_effect():
	var applied = false
	for item in get_items_with_qualities({Words.QUALITY_DEFEAT: true}):
		if not item.is_on_lattice():
			continue  # we destroy items, perhaps it was removed already
		var piled_items = get_items_piled_with(item, true)
		for other_item in piled_items:
			if other_item.is_you:
				destroy_item(other_item)
				applied = true
	return applied


#   _____ _       _
#  / ____(_)     | |
# | (___  _ _ __ | | __
#  \___ \| | '_ \| |/ /
#  ____) | | | | |   <
# |_____/|_|_| |_|_|\_\
#
# Things that SINK will destroy all items they are piled with.
# They are destroyed in the process as well.
#

func apply_sink_effect():
	for item in get_things_with_qualities({Words.QUALITY_SINK: true}):
		if not item.is_on_lattice():
			continue  # we destroy items, perhaps it was removed already
		var piled_items = get_items_piled_with(item, false)
		var has_sunk := false
		for other_item in piled_items:
			destroy_item(other_item)
			has_sunk = true
			#break  # uncomment this to destroy a single item instead
		if has_sunk:
			destroy_item(item)


# __      __   _     _
# \ \    / /  (_)   | |
#  \ \  / /__  _  __| |
#   \ \/ / _ \| |/ _` |
#    \  / (_) | | (_| |
#     \/ \___/|_|\__,_|
#
#
# Things that are VOID destroy all items they are piled with.
# They are not destroyed themselves.
# 
# abyssal
# abyss
# violent
# hungry
# angry
# null

func apply_void_effect():
	for item in get_things_with_qualities({Words.QUALITY_VOID: true}):
		if not item.is_on_lattice():
			continue  # we destroy items, perhaps it was removed already
		var piled_items = get_items_piled_with(item, false)
		for other_item in piled_items:
#			if other_item.is_void:
#				pass  # two (or more) VOID atop another -> do something ?
			destroy_item(other_item)


# __          __        _
# \ \        / /       | |
#  \ \  /\  / /__  __ _| | __
#   \ \/  \/ / _ \/ _` | |/ /
#    \  /\  /  __/ (_| |   <
#     \/  \/ \___|\__,_|_|\_\
#
# Anything WEAK will be destroyed if it shares a tile with another item.
# The other item will be unaffected, unless it is also WEAK.
# Two (or more) WEAK items on the same tile should all be destroyed.
# Weak things will also be destroyed if they try to move out of the terrain.

func apply_weak_effect():
	var items_to_destroy := Array()
	for item in get_items_with_qualities({Words.QUALITY_WEAK: true}):
		var piled_items = get_items_piled_with(item)
		if not piled_items.empty():
			items_to_destroy.append(item)
	for item in items_to_destroy:
		destroy_item(item)


#   ____                       _______ _           _
#  / __ \                     / / ____| |         | |
# | |  | |_ __   ___ _ __    / / (___ | |__  _   _| |_
# | |  | | '_ \ / _ \ '_ \  / / \___ \| '_ \| | | | __|
# | |__| | |_) |  __/ | | |/ /  ____) | | | | |_| | |_
#  \____/| .__/ \___|_| |_/_/  |_____/|_| |_|\__,_|\__|
#        | |
#        |_|
# 
# When piled, _one_ OPEN item will "open" _one_ SHUT item.
# Both are destroyed.
# Something both OPEN and SHUT will destroy itself first.

func apply_open_effect() -> bool:
	var applied := false
	for item in get_items_with_qualities({Words.QUALITY_OPEN: true}):
		if not item.is_on_lattice():
			continue  # since we destroy items during this loop
		if item.is_shut:
			destroy_item(item)
			applied = true
			continue
		for other_item in get_items_piled_with(item, true):
			if other_item.is_text:
				continue
			if not other_item.is_on_lattice():
				breakpoint  # how did you end up here?  weird.
				continue
			if other_item.is_shut:
				if item != other_item:
					destroy_item(item)
				destroy_item(other_item)
				applied = true
				break
	return applied


#  _    _       _       ____  __      _ _
# | |  | |     | |     / /  \/  |    | | |
# | |__| | ___ | |_   / /| \  / | ___| | |_
# |  __  |/ _ \| __| / / | |\/| |/ _ \ | __|
# | |  | | (_) | |_ / /  | |  | |  __/ | |_
# |_|  |_|\___/ \__/_/   |_|  |_|\___|_|\__|
#
# Something HOT will destroy all items MELT on the same tile.
# The HOT item will be unaffected, unless it is also MELT.
#

func apply_hot_effect() -> bool:
	var applied := false
	for item in get_items_with_qualities({Words.QUALITY_HOT: true}):
		for other_item in get_items_piled_with(item):
			if not other_item.is_melt:
				continue
			destroy_item(other_item)
			applied = true
		if item.is_melt:
			destroy_item(item)
			applied = true
	
	return applied


#  _____           _
# |  __ \         | |
# | |__) |__   ___| |_
# |  ___/ _ \ / _ \ __|
# | |  | (_) |  __/ |_
# |_|   \___/ \___|\__|
#
# A POET transforms whatever is on its tile into text.
#

func apply_poet_effect() -> bool:
	var applied := false
	var items_lettered := Array()
	for poet in get_things_with_qualities({Words.QUALITY_POET: true}):
		
		var piled_items = get_things_piled_with(poet, false)
		for other_item in piled_items:
			assert(other_item != poet)
			other_item.is_text = true
			other_item.is_lit = false
			items_lettered.append(other_item)
			applied = true
	
	var fresh_sentences = get_possible_sentences()
	for item_lettered in items_lettered:
		item_lettered.reset_properties()
		apply_qualifying_sentences_to_item(fresh_sentences, item_lettered)
		item_lettered.update_aesthetics()
	
	return applied


#  __  __
# |  \/  |
# | \  / | _____   _____
# | |\/| |/ _ \ \ / / _ \
# | |  | | (_) \ V /  __/
# |_|  |_|\___/ \_/ \___|
#
# Will try to move in the direction the item faces,
# and if it cannot, it will reverse direction and… ?  Debate!
#

func apply_move_effect() -> bool:
	var any_applied := false
	var items_per_direction := Directions.build_directions_index()
	for item in get_items_with_qualities({Words.QUALITY_MOVE: true}):
		var direction = coerce_item_direction(item, item.direction)
		items_per_direction[direction].push_back(item)
	
	for direction in Directions.USED_DIRECTIONS:
		var items = items_per_direction[direction]
		var moved = try_move_items(items, direction)
		for item in moved['items_that_did_not_move']:
			item.reverse_direction()
			# Here we may choose ; should we retry or not?
			#moved = try_move_item(item, item.direction)
			item.update_aesthetics()
		if moved['any']:
			any_applied = true
	return any_applied


#  __  __
# |  \/  |
# | \  / | ___  _ __ ___
# | |\/| |/ _ \| '__/ _ \
# | |  | | (_) | | |  __/
# |_|  |_|\___/|_|  \___|
#
# An Item that is More will add a copy of itself on empty adjacent tiles.
# 

func apply_more_effect(sentences := Array()) -> bool:
	var applied := false
	for cloner in get_things_with_qualities({Words.QUALITY_MORE: true}):
		
		var adjacent_tiles = self.cell_lattice.get_adjacent_tiles_positions(
			cloner.tile_position
		)
		var valid_adjacent_tiles := Array()
		for adjacent_tile in adjacent_tiles:
			if self.cell_lattice.has_thing_on_tile(adjacent_tile):
				continue
			if not can_go_on_tile(adjacent_tile):
				continue
			valid_adjacent_tiles.push_back(adjacent_tile)
		
		for adjacent_tile in valid_adjacent_tiles:
			var item = spawn_item(cloner, {
				'tile_position': adjacent_tile,
			})
			apply_qualifying_sentences_to_item(sentences, item)
#			item.update_aesthetics()
		
		
#		var piled_items := get_things_piled_with(poet, false)
#		for other_item in piled_items:
#			assert(other_item != poet)
#			other_item.is_text = true
#			other_item.is_lit = false
#
#		var fresh_sentences = get_possible_sentences()
#		for other_item in piled_items:
#			other_item.reset_properties()
#			apply_qualifying_sentences_to_item(fresh_sentences, other_item)
#			other_item.update_aesthetics()
#			applied = true
	
	return applied


################################################################################


#  _   _ _ _   _                 _____      _ _   _
# | \ | (_) | | |               / ____|    (_) | | |
# |  \| |_| |_| |_ _   _ ______| |  __ _ __ _| |_| |_ _   _
# | . ` | | __| __| | | |______| | |_ | '__| | __| __| | | |
# | |\  | | |_| |_| |_| |      | |__| | |  | | |_| |_| |_| |
# |_| \_|_|\__|\__|\__, |       \_____|_|  |_|\__|\__|\__, |
#                   __/ |                              __/ |
#                  |___/                              |___/


func reset_qualities_and_stuff():
	for item in get_all_items():
		item.reset_properties()


func fix_gui_locks():
	# This methods helps skipping a bug in Godot's Editor.
	# The lock status is lost on children of CanvasLayer, so we enforce it.
	for node in $GuiLayer.get_children():
		node.set_meta("_edit_lock_", true)


#  _____            _                   _   _
# |  __ \          | |                 | | (_)
# | |  | | ___  ___| |_ _ __ _   _  ___| |_ _  ___  _ __
# | |  | |/ _ \/ __| __| '__| | | |/ __| __| |/ _ \| '_ \
# | |__| |  __/\__ \ |_| |  | |_| | (__| |_| | (_) | | | |
# |_____/ \___||___/\__|_|   \__,_|\___|\__|_|\___/|_| |_|
#
#

# Helps knowing which items are already
var destruction_queue := Array()

func destroy_item(item: Item):
	# … emit signals everywhere !
	
	# The lattice is our authoritative source of items,
	# not the scene tree.  We'll remove from the tree at the end.
	remove_item_from_lattice(item)
	
#	if item.is_in_movement():
		# wait?
	
	if item.is_you:
		shake_camera(DEFAULT_SHAKE_OPTIONS)
	else:
		shake_camera(SLIGHT_SHAKE_OPTIONS)
	
	item.animate_destruction()
	
	## THING IS BOOM ###########################################################
	if item.has_quality(Words.QUALITY_BOOM):
		if not self.destruction_queue.has(item):
			self.destruction_queue.append(item)
		var cells = self.cell_lattice.get_adjacent_cells_positions(item.cell_position)
		cells.append(item.cell_position)
		for cell in cells:
			var victims = self.cell_lattice.find_on_cell(cell)
			for victim in victims:
				if self.destruction_queue.has(victim):
					continue
				self.destruction_queue.append(victim)
				destroy_item(victim)
				self.destruction_queue.erase(victim)
		self.destruction_queue.erase(item)
	############################################################################
	
	## THING HAS THING #########################################################
	var sentences = get_possible_sentences()
	var remains = Array()
	var stuff_names = item.stuffing
	for remaining_thing_name in stuff_names:
		var remaining_thing = spawn_item(item, {
			'concept_name': remaining_thing_name
		})
		remains.append(remaining_thing)
	reindex_lattice()  # expensive!
	for thing in remains:
		# Now, if we apply the sentences to the created object,
		# beware of infinite loops!
		# …
		# Let's try applying qualities at least
		apply_qualifying_sentences_to_item(sentences, thing)
	############################################################################
	
	#ParticlesFx.emit("destruction", self.position)
	# put this in animate_destruction() and remove the yield
	# meanwhile:
	var delay = get_action_cooldown() * 0.9
	yield(get_tree().create_timer(delay), "timeout")
	assert(is_instance_valid(item), "something fishy is happening")
	if item and is_instance_valid(item):
		remove_item_from_scene(item)
		
		# UNDO fetches the Item back from the bin.
		# The Item has been removed from the scene tree, so
		# it is safe to mark the Item as ~latticeable now.
		# This is probably not the right place to do this restore operation.
		item.set_latticeability(true)


func remove_item_from_scene(item):
	items_layer.remove_child(item)


func remove_item_from_lattice(item):
	cell_lattice.remove_thing(item)
	# Perhaps this should listen to lattice signals instead
	item.set_latticeability(false)


func update_items_z_salience():
	pass
	# See Item.set_position(), where we bypass the z-dragon.
#	for item in get_all_items():
#		item.position.y += item.get_z_salience() * 0.01
#		item.z_index = item.get_z_salience()


#  _______ _
# |__   __(_)
#    | |   _ _ __ ___   ___
#    | |  | | '_ ` _ \ / _ \
#    | |  | | | | | | |  __/
#    |_|  |_|_| |_| |_|\___|
#
#

# Stats about this level
var __start_time := 0.0  # seconds
var __end_time := -1.0  # seconds


func get_current_time() -> float:
	"""
	Current time in seconds.
	Relative to the launch of the Game, if I'm not mistaken.
	"""
	return OS.get_ticks_msec() * 0.001


func restart_level_chronometer() -> void:
	self.__start_time = get_current_time()
	self.__end_time = -1.0


func stop_level_chronometer() -> void:
	self.__end_time = get_current_time()


func get_level_time() -> float:
	"""
	Time in seconds since the start of this level.
	"""
	if self.__end_time < 0:
		return 0.0
	return self.__end_time - self.__start_time


#   _____
#  / ____|
# | |     __ _ _ __ ___   ___ _ __ __ _
# | |    / _` | '_ ` _ \ / _ \ '__/ _` |
# | |___| (_| | | | | | |  __/ | | (_| |
#  \_____\__,_|_| |_| |_|\___|_|  \__,_|
#
#

const DEFAULT_SHAKE_OPTIONS := {
	'duration':  0.1,  # total duration of the effect, in seconds
	'punch':     Vector2(7, 7),  # maximum delta in x and y
	'smoothing': 0.03,  # in seconds, at the end, to (linearly) reduce punch
}

const SLIGHT_SHAKE_OPTIONS := {
	'duration':  0.1,  # total duration of the effect, in seconds
	'punch':     Vector2(4, 4),  # maximum delta in x and y
	'smoothing': 0.04,  # in seconds, at the end, to (linearly) reduce punch
}

onready var camera : Camera2D = $Camera2D

var __camera_position_before_shake : Vector2
var __is_shaking_camera_since := -1.0
var __camera_shake_options := DEFAULT_SHAKE_OPTIONS


func get_camera() -> Camera2D:
	return self.camera


func shake_camera(options:=DEFAULT_SHAKE_OPTIONS) -> int:
	if not get_camera():
		breakpoint
		return ERR_DOES_NOT_EXIST
	
	__camera_shake_options = options
	#self.camera_shake_options = Utils.merge(DEFAULT_SHAKE_OPTIONS, options)
	# perhaps clamp, instead? (be tolerant)
	assert(__camera_shake_options['smoothing'] <= __camera_shake_options['duration'])
	
	if __is_shaking_camera_since < 0:
		__camera_position_before_shake = get_camera().get_position()
	__is_shaking_camera_since = get_current_time()
	
	return OK


func process_screen_shake(_delta):
	if not get_camera():
		return
	
	if not AppSettings.get_setting("accessibility", "visual", "screenshake", true):
		return
	
	if __is_shaking_camera_since >= 0:
		var t := get_current_time() - __is_shaking_camera_since
		if t < __camera_shake_options['duration']:
			var punch = __camera_shake_options['punch']
			var start_smoothing_at = (
				__camera_shake_options['duration']
				-
				__camera_shake_options['smoothing']
			)
			if t >= start_smoothing_at:
				punch *= (1 - (t - start_smoothing_at) / (1.0 * __camera_shake_options['smoothing']))
			var x_range := range(-int(punch.x), int(punch.x))
			var y_range := range(-int(punch.y), int(punch.y))
			var x := 0
			if x_range:
				x = x_range[randi() % x_range.size()]
			var y := 0
			if y_range:
				y = y_range[randi() % y_range.size()]
			# I.  More coherent animation, staying close to the initial cam pos.
			get_camera().set_position(
				__camera_position_before_shake
				+
				Vector2(x, y)
			)
			# II. Creeping away animation, feels awkward
#			get_camera().position += Vector2(x, y)
		else:
			__is_shaking_camera_since = -1.0
			get_camera().set_position(__camera_position_before_shake)


#  ____             _                                   _
# |  _ \           | |                                 | |
# | |_) | __ _  ___| | ____ _ _ __ ___  _   _ _ __   __| |
# |  _ < / _` |/ __| |/ / _` | '__/ _ \| | | | '_ \ / _` |
# | |_) | (_| | (__|   < (_| | | | (_) | |_| | | | | (_| |
# |____/ \__,_|\___|_|\_\__, |_|  \___/ \__,_|_| |_|\__,_|
#                        __/ |
#                       |___/


#onready var background = $Background
#
#func resize_background():
#	"""
#	NOT WORKING FDR NOW.
#	We need to be able to account for the camera zoom.
#	Resize the background using the UI in your level, as a workaround.
#	"""
#	if not self.background.texture:
#		return
#
#	var sprite_size = self.background.texture.get_size()
#	var size = get_viewport().size
#	breakpoint
#	background.scale = size / sprite_size


#  _____            _
# |  __ \          | |
# | |__) |___ _ __ | | __ _ _   _
# |  _  // _ \ '_ \| |/ _` | | | |
# | | \ \  __/ |_) | | (_| | |_| |
# |_|  \_\___| .__/|_|\__,_|\__, |
#            | |             __/ |
#            |_|            |___/


func get_replay_string() -> String:
	var s := ""
	for action in self.actions_history:
		s += action.to_string()
	return s


#                _              _
#     /\        | |            | |
#    /  \  _   _| |_ ___  _ __ | | __ _ _   _
#   / /\ \| | | | __/ _ \| '_ \| |/ _` | | | |
#  / ____ \ |_| | || (_) | |_) | | (_| | |_| |
# /_/    \_\__,_|\__\___/| .__/|_|\__,_|\__, |
#                        | |             __/ |
#                        |_|            |___/


const CHARS_DOWN_LEFT := ['1', 'w', 'W', '<']
const CHARS_DOWN := ['2', 's', 'S']
const CHARS_DOWN_RIGHT := ['3', 'x', 'X', 'c', 'C']
const CHARS_LEFT := ['4', 'q', 'Q']
const CHARS_PASS := ['5', ' ', '+']
const CHARS_RIGHT := ['6', 'd', 'D']
const CHARS_UP_LEFT := ['7', 'a', 'A']
const CHARS_UP := ['8', 'z', 'Z']
const CHARS_UP_RIGHT := ['9', 'e', 'E']
const CHARS_UNDO := ['0', '-', '.', '/', '←']

# This is set by the feature runner,
# to make level completion behave differently.
var is_test_run := false

# Solutions are strings of numpad actions like 669974
# Autoplays are (were?) dev toggles for convenience during map making.
# We don't use them much.  CTRL+END works fine.
export var solution_a := ""
export var autoplay_a := false
export var solution_b := ""
export var autoplay_b := false
export var solution_c := ""
export var autoplay_c := false


var __inputs_left_to_autoplay := Array()


signal test_passed
signal test_failed


func ready_autoplay() -> void:
	if self.autoplay_a:
		start_autoplay(self.solution_a)
	elif self.autoplay_b:
		start_autoplay(self.solution_b)
	elif self.autoplay_c:
		start_autoplay(self.solution_c)


func start_any_autoplay() -> void:
	if self.solution_a:
		start_autoplay(self.solution_a)
	elif self.solution_b:
		start_autoplay(self.solution_b)
	elif self.solution_c:
		start_autoplay(self.solution_c)


func start_autoplay(input_characters: String) -> void:
	for i in range(input_characters.length()):
		self.__inputs_left_to_autoplay.append(input_characters[i])	


func process_autoplay(_delta) -> void:
	if is_editor_preview():
		return
	if not has_inputs_left_to_autoplay():
		return
	if is_cooling_down_between_actions():
		return
	
	execute_input_from_character(pop_autoplay_input())
	
	if not has_inputs_left_to_autoplay() and self.is_test_run:
		yield(get_tree().create_timer(0.5), "timeout")
		if is_completed():
			emit_signal("test_passed")
		else:
			emit_signal("test_failed")


func has_inputs_left_to_autoplay() -> bool:
	return not self.__inputs_left_to_autoplay.empty()


func pop_autoplay_input() -> String:
	return self.__inputs_left_to_autoplay.pop_front()


func execute_input_from_character(input_character: String) -> void:
	assert(input_character.length() == 1)
	var has_passed := false
	var has_undoed := false
	var has_moved := false
	if CHARS_DOWN_LEFT.has(input_character):
		has_moved = try_move(Directions.DOWN_LEFT)
	elif CHARS_DOWN.has(input_character):
		has_moved = try_move(Directions.DOWN)
	elif CHARS_DOWN_RIGHT.has(input_character):
		has_moved = try_move(Directions.DOWN_RIGHT)
	elif CHARS_LEFT.has(input_character):
		has_moved = try_move(Directions.LEFT)
	elif CHARS_PASS.has(input_character):
		has_passed = try_pass()
	elif CHARS_RIGHT.has(input_character):
		has_moved = try_move(Directions.RIGHT)
	elif CHARS_UP_LEFT.has(input_character):
		has_moved = try_move(Directions.UP_LEFT)
	elif CHARS_UP.has(input_character):
		has_moved = try_move(Directions.UP)
	elif CHARS_UP_RIGHT.has(input_character):
		has_moved = try_move(Directions.UP_RIGHT)
	elif CHARS_UNDO.has(input_character):
		has_undoed = try_undo()


#               _     _                                     _
#     /\       | |   (_)                                   | |
#    /  \   ___| |__  _  _____   _____ _ __ ___   ___ _ __ | |_ ___
#   / /\ \ / __| '_ \| |/ _ \ \ / / _ \ '_ ` _ \ / _ \ '_ \| __/ __|
#  / ____ \ (__| | | | |  __/\ V /  __/ | | | | |  __/ | | | |_\__ \
# /_/    \_\___|_| |_|_|\___| \_/ \___|_| |_| |_|\___|_| |_|\__|___/
#
#

func get_achievements() -> Array:
	var achievements := Array()
	if self.achievement_a:
		achievements.append(self.achievement_a)
	if self.achievement_b:
		achievements.append(self.achievement_b)
	if self.achievement_c:
		achievements.append(self.achievement_c)
	return achievements


func perhaps_trigger_achievements_on_turn() -> void:
	if is_editor_preview() or is_dummy_run():
		return
	for achievement in get_achievements():
		if achievement.should_trigger_on_turn(self):
			trigger_achievement(achievement)


func perhaps_trigger_achievements_on_victory() -> void:
	if is_editor_preview() or is_dummy_run():
		return
	for achievement in get_achievements():
		if achievement.should_trigger_on_victory(self):
			trigger_achievement(achievement)


# class_name is still broken on some machines on Godot 3.4
#func trigger_achievement(achievement: Achievement) -> void:
func trigger_achievement(achievement) -> void:
	SoundFx.play("success")
	Game.unlock_achievement(achievement)



#  _                       _
# | |                     (_)
# | |     ___   __ _  __ _ _ _ __   __ _
# | |    / _ \ / _` |/ _` | | '_ \ / _` |
# | |___| (_) | (_| | (_| | | | | | (_| |
# |______\___/ \__, |\__, |_|_| |_|\__, |
#               __/ | __/ |         __/ |
#              |___/ |___/         |___/
# Logging Trait v0.0.0

const LOG_LEVEL_DEBUG := 'debug'
const LOG_LEVEL_INFO := 'info'
const LOG_LEVEL_WARN := 'warn'
const LOG_LEVEL_ERROR := 'error'
const LOG_LEVEL_SILENT := 'silent'  # risky!

export(String, 'debug', 'info', 'warn', 'error', 'silent') var log_level \
	:= LOG_LEVEL_DEBUG

func debug(msg:String):
	if self.log_level == LOG_LEVEL_DEBUG:
		print(msg)

func info(msg:String):
	inform(msg)

func inform(msg:String):
	if self.log_level == LOG_LEVEL_DEBUG || self.log_level == LOG_LEVEL_INFO:
		print(msg)

func warn(msg:String):
	if self.log_level != LOG_LEVEL_ERROR && self.log_level != LOG_LEVEL_SILENT:
		printerr(msg)

func error(msg:String):
	shout(msg)

func shout(msg:String):
	if self.log_level != LOG_LEVEL_SILENT:
		printerr(msg)

