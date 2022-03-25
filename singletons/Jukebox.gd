extends Node

#       _       _        _
#      | |     | |      | |
#      | |_   _| | _____| |__   _____  __
#  _   | | | | | |/ / _ \ '_ \ / _ \ \/ /
# | |__| | |_| |   <  __/ |_) | (_) >  <
#  \____/ \__,_|_|\_\___|_.__/ \___/_/\_\
#
#
# Meant to be used as an Autoloaded Singleton.
# This Jukebox is home made. (and it reeks a little)
# Feel like improving it?  Do it!
# Know of a better lib?  Share it! (pleaaaase)
# 
# Specs
# -----
# 
# - Handles multiple tracks
# - Handles fades in/out (todo)
# - Handles limbo alternative (todo)
# - Handles ambiance playlists ?
# - Sets buses of songs (todo)


var __is_playing := false  # careful, the value in here is unreliable for now
var __playlists_by_name := Dictionary()
var __playlists := Array()

var __current_playlist: Playlist


func _ready():
	if Game:
		var _c
		_c = Game.connect("level_entered", self, "on_level_entered")
		_c = Game.connect("level_completed", self, "on_level_completed")
		_c = Game.connect("main_menu_entered", self, "on_main_menu_entered")
		_c = Game.connect("game_paused", self, "on_game_paused")
		_c = Game.connect("game_resumed", self, "on_game_resumed")
	collect_playlists()


func on_level_entered(_level_name):
	play_by_name("Story")


func on_level_completed():
#	print("level_completed")
	pass


func on_main_menu_entered():
#	print("main_menu_entered")
	play_by_name("StartMenu")


func on_game_paused():
#	print("game_paused")
	pass


func on_game_resumed():
#	print("game_resumed")
	pass


func play_playlist(playlist):
	if __current_playlist != playlist:
		stop()
		do_play(playlist)
		__current_playlist = playlist



func play_by_name(playlist_name):
	var playlist := get_playlist_by_name(playlist_name)
	if not playlist:
		printerr("Jukebox: playlist `%s' was not found." % [playlist_name])
		return
	if __current_playlist != playlist:
		stop()
		do_play(playlist)
		__current_playlist = playlist


# Meh.
#func play_first() -> void:
#	if self.__is_playing:
#		return
#
#	var playlist: Playlist
#
##	playlist = get_playlist_by_name(playlist_name)
#	playlist = get_first_playlist()
#	playlist.randomize_songs()
#	do_play(playlist)
#	__current_playlist = playlist


func stop():
	debug("%s: stopping all playlists (was playing: %s)" % [get_name(), __is_playing])
	for playlist in get_playlists():
		playlist.stop_song()
	self.__is_playing = false


func do_play(playlist: Playlist):
	debug("%s: starting playlist `%s' (was playing: %s)" % [
		get_name(), playlist.get_name(), __is_playing,
	])
	self.__is_playing = true
	playlist.play()


func get_first_playlist() -> Playlist:
	var playlists = get_playlists()
	assert(playlists, "Define at least one Playlist as child.")
	return playlists[0]


func get_playlist_by_name(playlist_name) -> Playlist:
	if not __playlists_by_name.has(playlist_name):
		return null
	var playlist = __playlists_by_name[playlist_name]
	assert(playlist, "Define at least one Playlist as child.")
	return playlist


func get_playlists() -> Array:
	if not self.__playlists:
		collect_playlists()
	return self.__playlists


func collect_playlists():
	__playlists_by_name.clear()
	__playlists.clear()
	
	for playlist in get_children():
		if playlist is Playlist:
			__playlists_by_name[playlist.name] = playlist
			__playlists.append(playlist)




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

