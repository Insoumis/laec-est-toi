extends Control


export var title: String = tr("Press anything to Continue") setget set_title, get_title
export var bbcode_template: String = "[center][shake]%s[/shake][/center]"


func _ready():
	if OS.has_feature('HTML5'):
		self.title = tr("Click to Continue")
	update_title()


func set_title(value: String) -> void:
	if not value:
		return
	title = value  # not self.title


func get_title() -> String:
	return title  # not self.title


func update_title() -> void:
	var bbcode_title = self.bbcode_template % [self.title]
	$PressStart.bbcode_text = bbcode_title
	$PressStartShadow.bbcode_text = bbcode_title
