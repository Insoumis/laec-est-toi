extends CPUParticles2D


# __      __   _       _   _ _        _____           _   _      _
# \ \    / /  | |     | | (_) |      |  __ \         | | (_)    | |
#  \ \  / /__ | | __ _| |_ _| | ___  | |__) |_ _ _ __| |_ _  ___| | ___  ___
#   \ \/ / _ \| |/ _` | __| | |/ _ \ |  ___/ _` | '__| __| |/ __| |/ _ \/ __|
#    \  / (_) | | (_| | |_| | |  __/ | |  | (_| | |  | |_| | (__| |  __/\__ \
#     \/ \___/|_|\__,_|\__|_|_|\___| |_|   \__,_|_|   \__|_|\___|_|\___||___/
#
#
# Autodetachable CpuParticles2D emitter.
# Can follow its parent.
# Use with restart() as usual, or restart_with_parameters()

# Someday we'll get `private` and no more `__`…
# https://github.com/godotengine/godot-proposals/issues/641

# Attach to parent otherwise
export var attach_to_grandparent := true


export var should_follow_shepherd := true


# Delay before creating the ephemereal.
# This effectively delays the pixels, in user perspective.
var ephemereal_delay := 0.100  # seconds


# Since this class spawns ephemereal instances of itself,
# we need to mark thos instances so they don't spawn others
var __is_ephemereal := false


# Only set in original/emittor
var __parent : Node2D
var __grandparent : Node2D


# Follow this node's position.  No smoothing.
# Set in ephemereal to follow the parent of its maker.
var __shepherd : Node2D


var __delay_timer : SceneTreeTimer
#var __delay_step_2_timer : SceneTreeTimer
var __lifespan_timer : SceneTreeTimer


func _process(delta):
	process(delta)


func process(_delta):
	if is_emitting() and self.should_follow_shepherd and has_shepherd():
		try_following_shepherd()


func restart():
	return restart_with_properties()


func restart_with_properties(extra_props := {}):
	var err = assert_scene_conformity()
	if OK != err:
		# We can't attach to parent or grandparent, so let's GTFO
		.restart()
	elif self.__is_ephemereal:
		if get_tree():
			self.__lifespan_timer = get_tree().create_timer(self.lifetime)
			var _connected = self.__lifespan_timer.connect(
				"timeout", self, "__exit_gracefully"
			)
			.restart()
	else:
		# We're going to make another ephemereal emitter and start it
		if get_tree():
			self.__delay_timer = get_tree().create_timer(ephemereal_delay)
			var _connected = self.__delay_timer.connect(
				"timeout", self, "__make_ephemereal", [extra_props]
			)


func __make_ephemereal(extra_props: Dictionary):
		var ephemereal = self.duplicate(true)
		ephemereal.set_script(get_script())
		ephemereal.mark_as_ephemereal()
		ephemereal.attach_to_grandparent = self.attach_to_grandparent
		ephemereal.ephemereal_delay = self.ephemereal_delay
		for key in extra_props:
			ephemereal.set(key, extra_props[key])
		
		if self.should_follow_shepherd:
			ephemereal.start_following(__parent)
			ephemereal.try_following_shepherd()
		if self.attach_to_grandparent and self.__grandparent:
			self.__grandparent.add_child(ephemereal)
		else:
			self.__parent.add_child(ephemereal)
		ephemereal.restart()
		
#		var ephref := weakref(ephemereal)
#
#		self.__delay_step_2_timer = get_tree().create_timer(self.lifetime)
#		var _c = self.__delay_step_2_timer.connect("timeout", self, "__restart_step_2", [ephref])
#
#
#func __restart_step_2(ephref: WeakRef):
#	if ephref.get_ref():
#		ephref.get_ref().queue_free()


func __exit_gracefully():
	#print("%s ephemereal exited gracefully" % self.name)
	queue_free()


func mark_as_ephemereal() -> void:
	self.__is_ephemereal = true


func assert_scene_conformity():
	self.__parent = get_parent()
	if not self.__parent:
		printerr("%s requires a parent node to work." % [self.name])
		return ERR_CANT_ACQUIRE_RESOURCE
	self.__grandparent = __parent.get_parent()
	if self.attach_to_grandparent and not self.__grandparent:
		printerr("%s requires a grandparent node to work." % [self.name])
		return ERR_CANT_ACQUIRE_RESOURCE
	return OK


func has_shepherd():
	return null != __shepherd


func try_following_shepherd():
	if has_shepherd():
		if __shepherd.is_inside_tree():
			set_position(__shepherd.get_position())
		else:
			stop_following_shepherd()


func start_following(shepherd:Node2D):
	__shepherd = shepherd


func stop_following_shepherd():
	__shepherd = null

