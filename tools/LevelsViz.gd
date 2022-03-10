extends Node2D

# This is a test, a draft, a PoC?  (Piece of Caca)
# Looks like a lot of work to get what I want.
# This shows levels and links betweeen them.
# 
# We'd need:
# - Mouse Drag & Drop
# - Keep levels up (don't rotate due to physics)
# - A less naive space repartition
# - …
# 

const Bubble = preload("res://tools/LevelVizBubble.tscn")
const LinkScene = preload("res://tools/LevelsVizLink.tscn")

var levels_pool: LevelsPoolClass

var bubbles := Dictionary()  # filepath => Bubble
var links := Dictionary()  # Link => LinkScene

onready var levels_table: DataTable = find_node("LevelsTable")


func _ready():
	
	prints("Starting Levels Viz…")
	
	Chronometer.start()
	# We could also use the singleton LevelsPool
	self.levels_pool = LevelsPoolClass.new()
	self.levels_pool.should_use_exclusion = false
	self.levels_pool.init_full()
	prints("LevelsPool#init_full():", Chronometer.stop(), "s")
	# LevelsPool#init_full(): 1.640474 s
	
	var header_row = [
		tr("Filepath"),
		tr("Title"),
		tr("Story"),
#		tr("Orphan"),
		tr("Parents"),
		tr("Children"),
	]
	levels_table.set_columns(header_row.size())
	levels_table.add_header_row(header_row)
	for level in self.levels_pool.get_levels():
		levels_table.add_row([
			level.level_filepath,
			level.title,
			bool_to_human(level.is_in_score),
#			bool_to_human(level.is_orphan),
			level.parents,
			level.portals.size(),
		])


func bool_to_human(value: bool):
	if value:
		return tr("YES")
	else:
		return tr("NO")

	
#	for link in levels_pool.levels_links:
##		var link = levels_pool.levels_links[filepath]
#		var scene = LinkScene.instance()
#		scene.left_position = bubbles[link.from].global_position
#		scene.right_position = bubbles[link.to].global_position
##		scene.position = Vector2(
##			(randf()-0.5)*2*100,
##			(randf()-0.5)*2*100
##		)
#		$LinksLayer.add_child(scene)
#
#		links[link] = scene
##		bubbles[filepath] = bubble
#func _process(_delta):
#	if not self.levels_pool:
#		return
#	if not self.levels_pool.levels_links:
#		return
#	for link in self.levels_pool.levels_links:
#		var from_bubble = self.bubbles[link.from]
#		var to_bubble = self.bubbles[link.to]
#		var force = to_bubble.position - from_bubble.position
#		var invert := false
#		if force.length() < 250:
#			invert = true
#		force *= 0.00001
#		if invert:
#			force *= -0.618
#		from_bubble.apply_central_impulse(force)
##		from_bubble.rotation_degrees = 0  # nope
#		to_bubble.apply_central_impulse(-1 * force)
#
#		var link_scene = self.links[link]
#		link_scene.left_position = self.bubbles[link.from].global_position
#		link_scene.right_position = self.bubbles[link.to].global_position


func _exit_tree():
	print("%s _exit_tree()" % self.name)  # nope, I never see this
	self.levels_pool.clear()

