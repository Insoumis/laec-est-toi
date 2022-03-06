extends HSplitContainer
#extends HBoxContainer

#  ______    _ _ _                        _   _       _ _
# |  ____|  | (_) |             /\       | | (_)     (_) |
# | |__   __| |_| |_ ___  _ __ /  \   ___| |_ ___   ___| |_ _   _
# |  __| / _` | | __/ _ \| '__/ /\ \ / __| __| \ \ / / | __| | | |
# | |___| (_| | | || (_) | | / ____ \ (__| |_| |\ V /| | |_| |_| |
# |______\__,_|_|\__\___/|_|/_/    \_\___|\__|_| \_/ |_|\__|\__, |
#                                                            __/ |
#                                                           |___/
# All the nitty-gritty of our level editor.
# - TileMap painting  (terrain)
# - Drag'n drop of Items  (concepts)
# 
# I wanted one file per Activity at first, but it was troublesome.
# Therefore we ended up handling all activities in this script.
# 


enum ACTIVITIES {
	TERRAIN,
	CONCEPTS,
}

const Item = preload("res://addons/laec-is-you/entity/Item.gd")
const ItemScene = preload("res://core/Item.tscn")

const SQRT3_INVERSE := 1.0 / sqrt(3.0)


onready var dock = $Dock/DockContainer
onready var camera: Camera2D = $Preview/PreviewContainer/Previewport/PreviewCamera
onready var viewport: Viewport = $Preview/PreviewContainer/Previewport
onready var viewport_container: ViewportContainer = $Preview/PreviewContainer
# tilemap type ought to be HexagonalTileMap (but class_name is broken)
onready var tilemap = $Preview/PreviewContainer/Previewport/Level/HexagonalTileMap
onready var level := $Preview/PreviewContainer/Previewport/Level
onready var items_layer := $Preview/PreviewContainer/Previewport/Level/Items
onready var concepts_list: ItemList = $Dock/DockContainer/ConceptsItemList
onready var tileset_list: ItemList = $Dock/DockContainer/TileSetItemList
onready var hexagon_cursor_gui = $Preview/PreviewContainer/Previewport/HexagonGui


var current_activity = ACTIVITIES.TERRAIN
var hex_size := 64.0  # in pixels.  We grab it from tilemap when ready

var tileset : TileSet  # of the Terrain TileMap
var is_painting_terrain := false

# Perhaps move this into BrushCursor ; but this is performant as is (cached)
var current_tileset_brush := -1  # id in the tileset, -1 if none

var selection_bg_color := Color("#ff00ff")


class BrushCursor:
	extends Reference
	var position: Vector2
	var snapped_position: Vector2
	var selected_cell: Vector2
	var selected_tile: Vector2



signal items_changed


func _ready():
	self.hex_size = self.tilemap.get_hex_size()
	# TERRAIN Activity
	build_tileset_gui()
	# CONCEPTS (aka ITEMS) Activity
	build_concepts_brushes_gui()
	# …
	
	if OK != connect("items_changed", self, "_on_items_changed"):
		printerr("Failed to connect to `items_changed` signal.")
	
	var _c = self.viewport_container.connect(
		"gui_input", self, "process_viewport_input"
	)
	self.viewport.size = Vector2(
		self.viewport_container.margin_right,
		self.viewport_container.margin_bottom
	)
	
	# Hotfix a super awesome and unexpected engine bug
	# Comment these and watch the viewport dump the GPU RAM  XD
	self.split_offset = 1
	for _i in 10:
		yield(get_tree(), "idle_frame")
	self.split_offset = 0

	# Resizing the right-side dock emits this signals
	_c = connect("dragged", self, "_on_Split_dragged")
	
	# Disable the preview level camera, or the viewport will glitch on zoom
	self.level.camera.current = false


func _on_Split_dragged(_offset):
	pass


func _on_items_changed():
	self.level.spend_turn(true)


#  _____                   _
# |_   _|                 | |
#   | |  _ __  _ __  _   _| |_ ___
#   | | | '_ \| '_ \| | | | __/ __|
#  _| |_| | | | |_) | |_| | |_\__ \
# |_____|_| |_| .__/ \__,_|\__|___/
#             | |
#             |_|


# We use the _gui_input of our child viewport container through a signal instead
#func _gui_input(event):
#	process_viewport_input(event)


func process_viewport_input(event):
	process_common_viewport_input(event)
	if self.current_activity == ACTIVITIES.TERRAIN:
		process_terrain_viewport_input(event)
	elif self.current_activity == ACTIVITIES.CONCEPTS:
		process_concepts_viewport_input(event)


func process_common_viewport_input(event):
	if event is InputEventMouseMotion:
		var brush_cursor := get_brush_cursor(event)
		assert(brush_cursor)
		assert(null != brush_cursor.snapped_position)  # ?  what happened ?
#		self.hexagon_cursor_gui.position = brush_cursor.snapped_position
		update_hex_gui_position(brush_cursor.snapped_position)


func process_concepts_viewport_input(event):
	if event is InputEventMouseMotion:
		if self.is_dragging_concept:
			var brush_cursor := get_brush_cursor(event)
			self.dragged_item.position = brush_cursor.position
	
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and not event.pressed:
			if not self.is_dragging_concept:
				return  # swiping in emptiness leads here
			self.dragged_item.infer_position()
			self.dragged_item = null
			emit_signal("items_changed")
			self.is_dragging_concept = false
		
		elif event.button_index == BUTTON_LEFT and event.pressed:
			if self.is_dragging_concept:
				# double clicks, eg: raise volume while dragging
				return
			var brush_cursor := get_brush_cursor(event)
			var items := get_items_in_tree()
			var selected_item
			for item in items:
				if item.cell_position == brush_cursor.selected_cell:
					selected_item = item
					break
#				if item.cell_position == brush_cursor.selected_cell:
#					item.queue_free()
			if selected_item:
				self.is_dragging_concept = true
				self.dragged_item = selected_item
		
		elif event.button_index == BUTTON_RIGHT and event.pressed:
			if self.is_dragging_concept:
				# Drop a copy of the dragged item
				var brush_cursor := get_brush_cursor(event)
				var item = ItemScene.instance()
				if self.dragged_item and is_instance_valid(self.dragged_item):
					item.copy_from_item(self.dragged_item)
					self.items_layer.add_child(item)
					#perhaps this one-liner API?
					#item.relocate_to_position(brush_cursor.position)
					item.position = brush_cursor.position
					item.infer_position()
					##################
					emit_signal("items_changed")
				return
			var brush_cursor := get_brush_cursor(event)
			var items := get_items_in_tree()
			for i in range(items.size()-1, -1, -1):  # more salient first
				var item = items[i]
				if item.cell_position == brush_cursor.selected_cell:
					self.level.destroy_item(item)
					emit_signal("items_changed")
					break
	

func process_terrain_viewport_input(event):
	if not self.tilemap:
		breakpoint  # never triggered; I guess _gui_input starts after _ready?
		return
	
	var should_erase := false
	var brush_cursor : BrushCursor
	if event is InputEventMouse:
		brush_cursor = get_brush_cursor(event)
		if event.button_mask & BUTTON_MASK_RIGHT:
			should_erase = true
	
	if event is InputEventMouseMotion:
		assert(brush_cursor)
		assert(null != brush_cursor.snapped_position)  # ?  what happened ?
		
		if self.is_painting_terrain:
			paint_terrain_on_cursor(brush_cursor, should_erase)
	
	if event is InputEventMouseButton:
		if not (
			event.button_index == BUTTON_LEFT
			or 
			event.button_index == BUTTON_RIGHT
		):
			return  # skip mousewheel and other buttons for now
		
		if event.button_index == BUTTON_RIGHT:
			should_erase = true
		
		if event.pressed:
			__handle_terrain_mouse_press(event, brush_cursor, should_erase)
		else:
			__handle_terrain_mouse_depress(event, brush_cursor, should_erase)


func __handle_terrain_mouse_press(
		event: InputEventMouseButton,
		brush_cursor: BrushCursor,
		should_erase: bool
	):
	var should_pipette := false
	if self.is_painting_terrain:
		# User is probably clicking both mouse buttons at the same time
		debug("Already painting.  Cancelling…")
		self.is_painting_terrain = false
		return
	if event.control:
		if not should_erase:
			should_pipette = true
	if should_pipette:
		var tile_id_under_cursor := get_tile_id_under_cursor(brush_cursor)
		self.current_tileset_brush = tile_id_under_cursor
		if -1 != tile_id_under_cursor:  # An empty space was clicked on
			self.tileset_list.select(tile_id_under_cursor)
		else:
			self.tileset_list.unselect_all()
		update_terrain_selector_background(tile_id_under_cursor)
		self.tileset_list.ensure_current_is_visible()  # lastly
		return
	self.current_tileset_brush = get_terrain_selected_brush()
	self.is_painting_terrain = true
#	if should_erase:
#		debug("Starting erasing stroke.")
#	else:
#		debug("Starting painting stroke.")
	
	paint_terrain_on_cursor(brush_cursor, should_erase)


func __handle_terrain_mouse_depress(
		_event: InputEventMouseButton,
		_brush_cursor: BrushCursor,
		should_erase: bool
	):
	self.is_painting_terrain = false
	if should_erase:
		debug("Ending erasing stroke.")  # oddly, this is not printed
#	else:
#		debug("Ending painting stroke.")


#               _   _       _ _   _
#     /\       | | (_)     (_) | (_)
#    /  \   ___| |_ ___   ___| |_ _  ___  ___
#   / /\ \ / __| __| \ \ / / | __| |/ _ \/ __|
#  / ____ \ (__| |_| |\ V /| | |_| |  __/\__ \
# /_/    \_\___|\__|_| \_/ |_|\__|_|\___||___/
#
#

func change_activity(new_activity):
	if self.current_activity == new_activity:
		return
	self.current_activity = new_activity
	if self.current_activity == ACTIVITIES.TERRAIN:
		self.tileset_list.show()
		self.concepts_list.hide()
	elif self.current_activity == ACTIVITIES.CONCEPTS:
		self.tileset_list.hide()
		self.concepts_list.show()
	else:
		warn("Unknown activity `%s'." % [self.current_activity])
		breakpoint


#  _______                  _
# |__   __|                (_)
#    | | ___ _ __ _ __ __ _ _ _ __
#    | |/ _ \ '__| '__/ _` | | '_ \
#    | |  __/ |  | | | (_| | | | | |
#    |_|\___|_|  |_|  \__,_|_|_| |_|
#
# Basically a homemade TileMap editor.
#

func update_terrain_selector_background(tile_id: int):
	for tid in self.tileset_list.get_item_count():
		if tile_id == tid:
			self.tileset_list.set_item_custom_bg_color(tid, selection_bg_color)
		else:
			self.tileset_list.set_item_custom_bg_color(tid, Color.transparent)


func get_tile_id_under_cursor(brush_cursor: BrushCursor) -> int:
	return self.tilemap.get_cellv(brush_cursor.selected_tile)


func get_terrain_selected_brush() -> int:
	var selected_items := self.tileset_list.get_selected_items()
	if selected_items:
		return selected_items[0]
	return -1


func paint_terrain_on_cursor(brush_cursor: BrushCursor, should_erase := false):
	var tileset_id := self.current_tileset_brush
	if tileset_id == -1 and not should_erase:
#		breakpoint
		return  # skip painting if no brush is selected
	if should_erase:
		tileset_id = -1
	self.tilemap.set_cellv(
		brush_cursor.selected_tile,
		tileset_id
	)


#   _____                           _
#  / ____|                         | |
# | |     ___  _ __   ___ ___ _ __ | |_ ___
# | |    / _ \| '_ \ / __/ _ \ '_ \| __/ __|
# | |___| (_) | | | | (_|  __/ |_) | |_\__ \
#  \_____\___/|_| |_|\___\___| .__/ \__|___/
#                            | |
#                            |_|

var skipped_concepts := ['undefined', 'example']
var is_dragging_concept := false
var dragged_item : Node2D  # ItemScene


func get_items_in_tree() -> Array:  # of Item nodes
	var items_in_tree := Array()
	for item in self.items_layer.get_children():
		if item is Item:
			items_in_tree.append(item)
	return items_in_tree


func collect_available_items() -> Array:  # of PoolItem
	var available_items := Array()
	var possible_items = ItemsPool.list_items_sorted()
	for available_item in possible_items:
		if available_item.concept in self.skipped_concepts:
			continue
		available_items.append(available_item)
	return available_items


func __handle_concepts_list_mouse_move(event):
	if not self.is_dragging_concept:
		return
	if not self.dragged_item:
		return
	
	var brush_cursor := get_brush_cursor(event, true)
	self.dragged_item.position = brush_cursor.position
	update_hex_gui_position(brush_cursor.snapped_position)


func __handle_concepts_list_mouse_press(event):
	if event.button_index != BUTTON_LEFT:
		return
	if self.is_dragging_concept:
		__cancel_concepts_list_drag()
		return
	
	for i in 3:
		# wait for concepts_list's selected items
		yield(get_tree(), "idle_frame")
	
	var selected_concepts_ids := self.concepts_list.get_selected_items()
	if not selected_concepts_ids:
		return  # we clicked somewhere in the void between items
	var selected_concept_id = selected_concepts_ids[0]
	var selected_concept = self.concepts_list.get_item_metadata(selected_concept_id)
	
	var new_item := ItemScene.instance()
	new_item.concept_name = selected_concept.concept
	new_item.is_text = selected_concept.is_text
	
	self.is_dragging_concept = true
	self.dragged_item = new_item
	var connected := self.dragged_item.connect(
		"ready",
		self, "_on_item_dragged_ready",
		[event]
	)
	if OK != connected:
		warn("Failed to connect to dragged item's `ready` signal.")
		return
	self.items_layer.add_child(self.dragged_item)
	#debug("Adding item `%s' to the map" % self.dragged_item.concept_name)


func __handle_concepts_list_mouse_depress(event):
	if event.button_index == BUTTON_RIGHT:
		if self.is_dragging_concept:
			# Drop a copy of the dragged item
			if self.dragged_item and is_instance_valid(self.dragged_item):
				#var brush_cursor := get_brush_cursor(event)
				#perhaps this one-liner to share with other control listener?
				#__spawn_copy_of_item(self.dragged_item, brush_cursor)
				var item = ItemScene.instance()
				item.copy_from_item(self.dragged_item)
				self.items_layer.add_child(item)
				#perhaps this one-liner API?
				#item.relocate_to_position(brush_cursor.position)
				item.position = self.dragged_item.position
				item.infer_position()
				############################
				emit_signal("items_changed")
				#############################################################
			return
	
	if event.button_index == BUTTON_LEFT:
		if not self.is_dragging_concept:
			__cancel_concepts_list_drag()  # superfluous perhaps
			return
		self.is_dragging_concept = false
		if self.dragged_item and is_instance_valid(self.dragged_item):
			var pos = self.dragged_item.position
			self.dragged_item.infer_position(true)
			if not self.dragged_item.is_on_screen():
				debug("Removing item `%s' that is out of bounds" % self.dragged_item.concept_name)
				self.level.destroy_item(self.dragged_item)
				self.dragged_item = null
				emit_signal("items_changed")
				return
			
			#self.dragged_item.relocate_to_position(pos)
			self.dragged_item.position = pos
			self.dragged_item.infer_position()
			self.dragged_item = null
			emit_signal("items_changed")
	

func __cancel_concepts_list_drag():
	self.is_dragging_concept = false
	if self.dragged_item != null:
		self.level.destroy_item(self.dragged_item)
#		self.dragged_item.queue_free()  # use this if the above causes trouble
		self.dragged_item = null


func _on_concepts_list_gui_input(event: InputEvent):
#	debug("_on_concepts_list_gui_input %s" % event)
	if event is InputEventMouseMotion:
		__handle_concepts_list_mouse_move(event)
	
	if event is InputEventMouseButton:
#		if event.button_index == BUTTON_LEFT:
		if event.pressed:
			__handle_concepts_list_mouse_press(event)
#				dim_dock()
		else:
			__handle_concepts_list_mouse_depress(event)
#				restore_dock()


func _on_item_dragged_ready(event):
	# Helps hiding the item from (0, 0) by positioning it as soon as possible
	# and not waiting for a mouse move that will handle the position.
	__handle_concepts_list_mouse_move(event)
	self.dragged_item.infer_position()


#  _____             _
# |  __ \           | |
# | |  | | ___   ___| | __
# | |  | |/ _ \ / __| |/ /
# | |__| | (_) | (__|   <
# |_____/ \___/ \___|_|\_\
#
#


func dim_dock():
	self.dock.modulate = Color.transparent

func restore_dock():
	self.dock.modulate = Color.white


#   _____
#  / ____|
# | |    _   _ _ __ ___  ___  _ __
# | |   | | | | '__/ __|/ _ \| '__|
# | |___| |_| | |  \__ \ (_) | |
#  \_____\__,_|_|  |___/\___/|_|
#
#

# Short history of selected cells to show direction on the gui hexagon
var currently_selected_cell := Vector2(0, 0)
var previously_selected_cell := Vector2(0, 0)


func update_hex_gui_position(new_position: Vector2):
	var cursor_direction = get_cursor_direction()
	if self.hexagon_cursor_gui and is_instance_valid(self.hexagon_cursor_gui):
		self.hexagon_cursor_gui.position = new_position
		var items: Array = self.level.get_items_on(self.currently_selected_cell)
		if items:
			self.hexagon_cursor_gui.mark_direction(items[0].direction)
		else:
			self.hexagon_cursor_gui.release_direction()
	if self.dragged_item and is_instance_valid(self.dragged_item):
		self.hexagon_cursor_gui.mark_direction(cursor_direction)
		if self.dragged_item.direction != cursor_direction:
			self.dragged_item.direction = cursor_direction
			self.dragged_item.update_aesthetics()


func get_cursor_direction():
	var d = HexagonalLattice.get_direction_to_adjacent(
		self.previously_selected_cell,
		self.currently_selected_cell
	)
	return Directions.from_cell(d)


func get_brush_cursor(event: InputEventMouse, relative_to_dock:=false) -> BrushCursor:
	var mouse_position: Vector2 = event.position
#	var hex_radius = self.hex_size * SQRT3_INVERSE
	var rekt := self.viewport_container.get_rect().size / 2.0
	
	if relative_to_dock:
		mouse_position += Vector2(1, -1) * rekt
		mouse_position *= self.camera.zoom
	else:
		mouse_position -= rekt
		mouse_position *= self.camera.zoom
	var lattice : HexagonalLattice = self.level.get_items_lattice()
	var cell := lattice.pixel_to_cell(mouse_position)
	var tile := HexagonalLattice.cell_to_tile(cell)
	var snap := lattice.cell_to_pixel(cell)
	
	var brush_cursor := BrushCursor.new()
	brush_cursor.position = mouse_position
	brush_cursor.snapped_position = snap
	brush_cursor.selected_cell = cell
	brush_cursor.selected_tile = tile
	
	if cell != self.currently_selected_cell:
		self.previously_selected_cell = self.currently_selected_cell
		self.currently_selected_cell = cell
	
	return brush_cursor


#   _____       _
#  / ____|     (_)
# | |  __ _   _ _
# | | |_ | | | | |
# | |__| | |_| | |
#  \_____|\__,_|_|
#
#

func build_tileset_gui():
	# What to do with this ?  Here is fine for now.
	self.tileset = preload("res://tilesets/GroundTileSet.tres")
	
	self.tileset_list.max_columns = 0
	
	var i := 0
	for tile_id in tileset.get_tiles_ids():
		#var tile_name := tileset.tile_get_name(tile_id)
		#self.tileset_list.add_item(tile_name)  # looks better without it
		#self.tileset_list.add_item("")
		self.tileset_list.add_icon_item(tileset.tile_get_texture(tile_id))
		self.tileset_list.set_item_metadata(i, tile_id)
		i += 1
	
	self.tileset_list.select(0)
	update_terrain_selector_background(0)
	var _c = self.tileset_list.connect(
		"item_selected", self, "update_terrain_selector_background"
	)


func build_concepts_brushes_gui():
	var shiver_length := 3  # frames of shiver, get from SpriteFramesFactory?
	self.concepts_list.icon_mode = ItemList.ICON_MODE_TOP
#	self.concepts_list.fixed_column_width = 64
	self.concepts_list.max_columns = 0
	
	var i := 0
	for available_item in collect_available_items():
		# We cannot use AtlasTextures in AnimatedTextures, so no atlas here for now
#		var item_sprite_frames := AtlasSpriteFramesFactory.get_for_concept(
		var item_sprite_frames := SpriteFramesFactory.get_for_concept(
			available_item.concept, available_item.is_text
		)
		var animated_icon := AnimatedTexture.new()
		animated_icon.set_frames(shiver_length)
		for shiver in shiver_length:
#			var animation_name = "%s_0" % available_item.get_animation_prefix_for(Directions.RIGHT)
			var animation_name = "%s_0" % Directions.as_string(Directions.RIGHT)
			var icon := item_sprite_frames.get_frame(animation_name, shiver)
			assert(icon)
			animated_icon.set_frame_texture(shiver, icon)
		self.concepts_list.add_icon_item(animated_icon)
		self.concepts_list.set_item_tooltip(i, 
			('text_' if available_item.is_text else '')
			+
			available_item.concept
		)
		self.concepts_list.set_item_tooltip_enabled(i, true)
		self.concepts_list.set_item_metadata(i, available_item)
		
		i += 1
	
	var _c = self.concepts_list.connect(
		"gui_input", self, "_on_concepts_list_gui_input"
	)



#   _____
#  / ____|
# | (___   __ ___   _____
#  \___ \ / _` \ \ / / _ \
#  ____) | (_| |\ V /  __/
# |_____/ \__,_| \_/ \___|
#
#


func reset():
	self.tilemap.clear()
	for item in get_items_in_tree():
		item.queue_free()


### REFACTO ME USING LEVEL.TO_PICKLE() #########################################
func terrain_to_pickle() -> Dictionary:
	var pickle := Dictionary()
	
	for tile in self.tilemap.get_used_cells():
		pickle[tile] = self.tilemap.get_cellv(tile)
	
	return pickle
func concepts_to_pickle() -> Array:
	var pickle := Array()
	
	for item in get_items_in_tree():
		pickle.append(item.to_pickle())
	
	return pickle
func to_pickle() -> Dictionary:
	return {
		'terrain': terrain_to_pickle(),
		'concepts': concepts_to_pickle(),
		'zoom': self.level.camera.zoom,
	}
################################################################################


func load_from_pickle(pickle: Dictionary) -> int:
	
	# Duplicate of Level.load_from_pickle ; refactor at some point
	
	if not (pickle is Dictionary):
		return ERR_INVALID_PARAMETER
	
	if not pickle.has('terrain'):
		return ERR_INVALID_PARAMETER
	if not (pickle['terrain'] is Dictionary):
		return ERR_INVALID_PARAMETER
	
	if not pickle.has('concepts'):
		return ERR_INVALID_PARAMETER
	if not (pickle['concepts'] is Array):
		return ERR_INVALID_PARAMETER
	
	reset()
	
	for tile in pickle.get('terrain', {}).keys():
		self.tilemap.set_cellv(tile, pickle['terrain'][tile])
	for item_pickle in pickle.get('concepts', []):
		var item = ItemScene.instance()
		item.from_pickle(item_pickle)
		self.items_layer.add_child(item)
		item.reposition()
		item.update_aesthetics()
	self.camera.zoom = pickle.get('zoom', Vector2.ONE)
	self.level.camera.zoom = pickle.get('zoom', Vector2.ONE)
	
	return OK


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

