extends Node
class_name ParticlesFactory

#  _____           _   _      _           ______         _
# |  __ \         | | (_)    | |         |  ____|       | |
# | |__) |_ _ _ __| |_ _  ___| | ___  ___| |__ __ _  ___| |_ ___  _ __ _   _
# |  ___/ _` | '__| __| |/ __| |/ _ \/ __|  __/ _` |/ __| __/ _ \| '__| | | |
# | |  | (_| | |  | |_| | (__| |  __/\__ \ | | (_| | (__| || (_) | |  | |_| |
# |_|   \__,_|_|   \__|_|\___|_|\___||___/_|  \__,_|\___|\__\___/|_|   \__, |
#                                                                       __/ |
#                                                                      |___/
# Instantiates particle emitters as-needed to allow some concurrency.
# Emitters are not freed, are added as siblings of this node, and are reused.

# Path to a Particles2D scene we're going to emit
export(String, FILE, "*.tscn") var particles_emitter_scene_path : String

# Allows *some* concurrency
export var max_concurrent_emitters := 8

# Usually parent in tree where we're going to put the shiny particles
var container: Node2D


# We use multiple emitters to allow some concurrency
var emitters := Array()  # of particle emitters scenes


# Index of the last used emitter
var last_used := -1


func _ready():
	self.container = get_parent()
	assert(self.container is Node2D, "or make this code better")


################################################################################


# @public
func emit(at_position: Vector2):
	do_emit(at_position, false)


# @public
func emit_once(at_position: Vector2):
	do_emit(at_position, true)


# func stop()  # → perhaps not, or choose between stop_last and stop_all ?
# func stop_all()
# func stop_last()


################################################################################


# @private
func do_emit(at_position: Vector2, one_shot := false):
	if (
		not self.container
		or
		not is_instance_valid(self.container)
		or
		not self.container.is_inside_tree()
	):
		return
	var emitter = find_most_available_emitter()
	emitter.position = at_position
	emitter.one_shot = one_shot
	emitter.emitting = true


# @private
func make_one_emitter():
	var emitter_pack = load(self.particles_emitter_scene_path)
	assert(emitter_pack, "%s: particles emitter scene is invalid" % [get_name()])
	var emitter = emitter_pack.instance()
	#emitter.one_shot = true
	emitter.emitting = false
	self.emitters.append(emitter)
	self.container.add_child(emitter)
	return emitter


# @private
func find_most_available_emitter():
	var emitter
	if self.emitters.size() == 0:  # is_empty() is coming in Godot 4  \o/
		emitter = make_one_emitter()
	self.last_used = (self.last_used + 1) % self.max_concurrent_emitters
	if self.last_used >= self.emitters.size():
		emitter = make_one_emitter()
	else:
		emitter = self.emitters[self.last_used]
	return emitter
