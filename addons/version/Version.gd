tool
extends Node

# Singleton helping with version readings.
# Autoloaded by the plugin, you may access `Version` from anywhere.

var default_version := "0.0.0"
var version_file_path := "res://VERSION"

func get_full():
	var file = File.new()
	if file.file_exists(self.version_file_path):
		var err = file.open(self.version_file_path, File.READ)
		if err != OK:
			printerr("Version file `%s` exists but cannot be read." % self.version_file_path)
			return self.default_version
		var full = file.get_as_text().strip_edges()
		file.close()
		return full
	return self.default_version
