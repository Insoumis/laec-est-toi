extends ConfirmationDialog


onready var import_field := $Layout/ImportField


func _ready():
	if not self.import_field.text:
		var clip = OS.get_clipboard().strip_edges()
		if LevelReference.looks_like_phiu(clip):
			self.import_field.text = clip

func get_import_string() -> String:
	return self.import_field.text.strip_edges()
