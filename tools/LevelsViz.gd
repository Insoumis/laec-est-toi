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

var levels_pool : LevelsPoolClass

var bubbles := Dictionary()  # filepath => Bubble
var links := Dictionary()  # Link => LinkScene

func _ready():
	
	prints("Starting Levels Viz…")
	
	Chronometer.start()
	self.levels_pool = LevelsPoolClass.new()
	self.levels_pool.should_use_exclusion = false
	self.levels_pool.init()
	prints("LevelsPool#init():", Chronometer.stop(), "s")
	# LevelsPool#init(): 0.140474 s

	Chronometer.start()
	self.levels_pool.instance_levels()
	prints("LevelsPool#instance_levels():", Chronometer.stop(), "s")
	# LevelsPool#instance_levels(): 0.310439 s
	
	Chronometer.start()
	self.levels_pool.reindex_portals()
	prints("LevelsPool#reindex_portals():", Chronometer.stop(), "s")
	# LevelsPool#reindex_portals(): 0.001231 s
	
	
	prints("LevelsPool#levels_links size", self.levels_pool.levels_links.size())
	
	
	Chronometer.start()
	var orphans = self.levels_pool.find_orphans()
	prints("LevelsPool#find_orphans():", Chronometer.stop(), "s")
	
	prints("Found %d orphaned levels." % [orphans.size()])
	for orphan in orphans:
		prints("  orphan:", orphan)
	
	

	for filepath in levels_pool.instanced_levels:
		var level = levels_pool.instanced_levels[filepath]
		var bubble = Bubble.instance()
		bubble.position = Vector2(
			(randf()-0.5)*2*600,
			(randf()-0.5)*2*400
		)
		bubble.set_filepath(filepath)
		$PortalsLayer.add_child(bubble)
		bubbles[filepath] = bubble
	
	
	for link in levels_pool.levels_links:
#		var link = levels_pool.levels_links[filepath]
		var scene = LinkScene.instance()
		scene.left_position = bubbles[link.from].global_position
		scene.right_position = bubbles[link.to].global_position
#		scene.position = Vector2(
#			(randf()-0.5)*2*100,
#			(randf()-0.5)*2*100
#		)
		$LinksLayer.add_child(scene)
		
		links[link] = scene
#		bubbles[filepath] = bubble
	
	
	
	#self.levels_pool.clear()

#func update_links():


func _process(delta):
	if not self.levels_pool:
		return
	if not self.levels_pool.levels_links:
		return
	for link in self.levels_pool.levels_links:
		var from_bubble = self.bubbles[link.from]
		var to_bubble = self.bubbles[link.to]
		var force = to_bubble.position - from_bubble.position
		var invert := false
		if force.length() < 250:
			invert = true
		force *= 0.00001
		if invert:
			force *= -0.618
		from_bubble.apply_central_impulse(force)
#		from_bubble.rotation_degrees = 0  # nope
		to_bubble.apply_central_impulse(-1 * force)
		
		var link_scene = self.links[link]
		link_scene.left_position = self.bubbles[link.from].global_position
		link_scene.right_position = self.bubbles[link.to].global_position


func _exit_tree():
	print("%s _exit_tree()" % self.name)  # nope, I never see this
	self.levels_pool.clear()

