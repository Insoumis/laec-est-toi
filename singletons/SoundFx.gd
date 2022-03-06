extends Node

#   _____                       _ ______
#  / ____|                     | |  ____|
# | (___   ___  _   _ _ __   __| | |____  __
#  \___ \ / _ \| | | | '_ \ / _` |  __\ \/ /
#  ____) | (_) | |_| | | | | (_| | |   >  <
# |_____/ \___/ \__,_|_| |_|\__,_|_|  /_/\_\
#
# Sound effects singleton, helps playing GUI and game sounds.
# This is for WAV, we use the Jukebox instead for the OGG music.
# 
# Play a sound stored in the sound_files_directory :
#     SoundFx.play('gui_pouic')
# Use subdirectories if you want (we don't ; for now) :
#     SoundFx.play('gui/beep')
# Be careful where you get the sound name from :
#     SoundFx.play('../secret/boop')


# We'll detect .wav files in here (or subdirs of it)
export var sound_files_directory := "res://sounds"


export var bus := "Effect"


# Perhaps we'll use multiple audio players at some point
var player: AudioStreamPlayer

# Instances of WAV files, ready to feed the audio stream
# Don't .clear() this, use empty_sound_cache() instead.
var sounds_cache := Dictionary()


func _ready():
	instantiate_players()


func _exit_tree():
	empty_sounds_cache()
	free_players()  # redundant with node unloading, but should not hurt


func play(sound_name: String) -> void:
	"""
	sound_name: name of the file without .wav extension
		Example sound names:
			- gui_pouic
			- fanfare
		Best not use spaces in here, since it becomes a filesystem path.
	"""
	var sound = get_sound(sound_name)
	if sound:
		self.player.stream = sound
		self.player.play()
	else:
		breakpoint


# We might have more than one later, to allow for *some* sound concurrency.
func instantiate_players() -> void:
	if self.player:
		self.player.queue_free()
	self.player = AudioStreamPlayer.new()
	self.player.set_name("AudioStreamPlayer")
	self.player.set_bus(self.bus)
	add_child(self.player)


func free_players() -> void:
	if self.player:
		self.player.queue_free()


func get_sound(sound_name: String) -> AudioStreamSample:
	if self.sounds_cache.has(sound_name):
		return self.sounds_cache[sound_name]
	var sound_path = "%s/%s.wav" % [self.sound_files_directory, sound_name]
	var sound = load(sound_path)  # AudioStreamSample, extends Reference
	assert(sound, "No sound `%s' found.  Looked here: %s" % [sound_name ,sound_path])
	if sound:
		self.sounds_cache[sound_name] = sound
	return sound


func empty_sounds_cache() -> void:
	if self.sounds_cache.empty():  # is_empty()   T_T
		return
#	for sound_name in self.sounds_cache:
#		# It's OK, sound samples are references we don't need to free()
#		self.sounds_cache[sound_name].free()
	self.sounds_cache.clear()

