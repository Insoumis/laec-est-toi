extends ClipboardMirrorBehavior
class_name PhiuClipboardMirrorBehavior


const LevelReferenceScript = preload("res://core/LevelReference.gd")


func should_use_clipboard_contents(clipboard_contents: String) -> bool:
	return LevelReferenceScript.looks_like_phiu(clipboard_contents)
