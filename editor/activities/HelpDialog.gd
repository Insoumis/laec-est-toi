extends AcceptDialog


func _ready():
	var _c = $Layout/HelpText.connect("meta_clicked", self, "_on_meta_clicked")


func _on_meta_clicked(meta: String):
	print("Opening link %s in browser..." % meta)
	var opened = OS.shell_open(meta)
	if opened != OK:
		printerr("Failed to open link %s" % meta)

