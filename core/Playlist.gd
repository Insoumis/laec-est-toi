extends Node
class_name Playlist

#  _____  _             _ _     _
# |  __ \| |           | (_)   | |
# | |__) | | __ _ _   _| |_ ___| |_
# |  ___/| |/ _` | | | | | / __| __|
# | |    | | (_| | |_| | | \__ \ |_
# |_|    |_|\__,_|\__, |_|_|___/\__|
#                  __/ |
#                 |___/
# 
# 

export var play_at_random := false
var random_seed := 42  # export once implemented

# Pause betwwen tracks
var pause_duration := 11.0

var __current_song : AudioStreamPlayer
var __songs := Array()
var __songs_by_name := Dictionary()


func _ready():
	if self.play_at_random:
		randomize_songs(self.random_seed)


func play():
	var next_song = get_first_song()
#	next_song.play()
	play_song(next_song)


func stop_song():
	disconnect_from_current_song()
	for other_song in get_songs():
		fade_song_out(other_song)


func play_song(song):
	if not is_song(song):
		if song is String:
			song = get_song_by_name(song)
		else:
			assert(false, "Not Implemented")
	
	disconnect_from_current_song()
	
	for other_song in get_songs():
		fade_song_out(other_song)
	fade_song_in(song)
	self.__current_song = song
	connect_to_current_song()


func connect_to_current_song():
	if not self.__current_song:
		return
	if OS.has_feature("HTML5"):
		# WHYYYYYYYY, the audioEnd signal takes a lot of time to come back and is fired when stopping songs,
		# therefore we manually wait the time until the next song...
		yield(get_tree().create_timer(202.0), "timeout")
		on_song_finished()
#		var _connected = AudioManager.connect("audioEnd",self,"on_song_finished")
#		if OK != _connected:
#			printerr("Jukebox Playlist: failed to connect to the current song")
	else:
		var _connected = self.__current_song.connect(
			"finished", 
			self, 'on_song_finished'
		)
		if OK != _connected:
			printerr("Jukebox Playlist: failed to connect to the current song")


func disconnect_from_current_song():
	if not self.__current_song:
		return
	if OS.has_feature("HTML5"):
		if AudioManager.is_connected("audioEnd",self,"on_song_finished"):
			AudioManager.disconnect("audioEnd",self,"on_song_finished")
	else:
		if self.__current_song.is_connected("finished", self, 'on_song_finished'):
			self.__current_song.disconnect("finished", self, 'on_song_finished')


func on_song_finished(_a = null):
	yield(get_tree().create_timer(pause_duration), "timeout")
	if Jukebox.__current_playlist == self:
#		print(_a)
#		print("self", self)
#		print("current playlist", Jukebox.__current_playlist)
		var next_song = get_next_song()
		if next_song:
			play_song(next_song)


func get_next_song() -> AudioStreamPlayer:
	if not self.__current_song:
		if self.__songs.empty():
			return null
		return self.__songs[0]
	var i = self.__songs.find(self.__current_song)
	assert(i >= 0, "what?")
	i = (i + 1) % (self.__songs.size())  # loop !
	
	return self.__songs[i]


func fade_song_out(song:AudioStreamPlayer):
	if OS.has_feature("HTML5"):
		var song_name = song.stream.resource_path.replace("res://sounds/music/precheurius/", "")
		if AudioManager.get_audios_playing_on_group("ogg").find(song_name) != -1:
			AudioManager.stop(song_name)
	else:
		song.stop()


func fade_song_in(song:AudioStreamPlayer):
	if OS.has_feature("HTML5"):
		AudioManager.play(song.stream.resource_path.replace("res://sounds/music/precheurius/", ""), {})
	else:
		song.play()
	


func get_first_song() -> AudioStreamPlayer:
	var songs = get_songs()
	assert(songs, "Add some AudioStreamPLayers as children, one per song.")
	return songs[0]


func get_song_by_name(song_name:String) -> AudioStreamPlayer:
	collect_songs()
	assert(
		self.__songs_by_name.has(song_name),
		"No song named `%s' could be found." % [song_name]
	)
	if self.__songs_by_name.has(song_name):
		return self.__songs_by_name[song_name]
	return null


func get_songs() -> Array:
	collect_songs()
	return self.__songs


func collect_songs(invalidate_cache := false):
	if not invalidate_cache and not self.__songs.empty():
		return
	
	self.__songs.clear()
	self.__songs_by_name.clear()
	
	for song in get_children():
		if not is_song(song):
			continue
		self.__songs.append(song)
		self.__songs_by_name[song.name] = song


func randomize_songs(_rng_seed := 42):
	collect_songs()
	
	randomize()
	self.__songs.shuffle()
	
	assert(_rng_seed == 42, "seed not implemented")
	# Use RNG instead, but we need shuffle_array() util first
	# and also set the seed only once to traverse the pseudo random.
#	var rng = RandomNumberGenerator.new()
#	rng.set_seed(rng_seed)
#	rng.shuffle_array(self.__songs)


func is_song(node: Node) -> bool:
	return (
		node is AudioStreamPlayer
		and
		node.stream
	)
