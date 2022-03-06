extends Node
class_name ClipboardMirrorBehavior

# Node to add as child of a TextEdit (or LineEdit perhaps eventually)
# Will make the parent TextEdit grab the clipboard contents as best it can.
# Includes a fix for HTML5 where unicode chars were eaten by OS.get_clipboard().


# Override this with your custom definition
func should_use_clipboard_contents(_clipboard_contents: String) -> bool:
	return true


func get_field():
	var field = get_parent()
	if not field or not is_instance_valid(field):
		breakpoint
		return null
	assert(field is TextEdit, "Set %s as child of a TextEdit." % name)
	return field


func _ready():
	ready()  # allows overriding


func ready():
	setup()


func setup():
	var field = get_field()
	if not field:
		breakpoint
		return
	
	if not field.text:
		var clip = OS.get_clipboard()
		if should_use_clipboard_contents(clip):
			field.text = clip
	
	if Engine.has_singleton("JavaScript"):
		
		# Exploring the new Clipboard API, not implemented on my Firefox yet
#		JavaScript.eval("navigator.permissions.query({ name: 'clipboard-read' });")
#		JavaScript.eval("""
#if (navigator) {
#	if (navigator.clipboard) {
#		//var clip = await navigator.clipboard.readText();
#		if (navigator.clipboard.readText) {
#			navigator.clipboard.readText().then((text) => {
#				console.log("navigator.clipboard.readText().then", text);
#			});
#		} else if (navigator.clipboard.read) {
#			navigator.clipboard.read().then((data) => {
#				console.log("navigator.clipboard.read().then", data);
#			});
#		} else {
#			console.warn("No usable method in navigator.clipboard")
#		}
#	} else {
#		console.log("No navigator.clipboard variable.")
#	}
#} else {
#	console.log("No navigator variable.")
#}
#		""")
		
		# Working solution for now
		JavaScript.eval("""
function handlePaste (e) {
	var clipboardData, pastedData;

	e.stopPropagation();
	e.preventDefault();

	clipboardData = e.clipboardData || window.clipboardData;
	pastedData = clipboardData.getData('Text');
	
	console.info("Setting window.latestPaste", pastedData);
	window.latestPaste = pastedData;
}

window.addEventListener('paste', handlePaste);
		""")

		field.connect("text_changed", self, "_on_Field_text_changed")


var ignore_next_text_change := false
func _on_Field_text_changed():
	if self.ignore_next_text_change:
		self.ignore_next_text_change = false
		return
	
	var field = get_field()
	if not field:
		breakpoint
		return
	
	var latestPaste = JavaScript.eval("window.latestPaste")
#	if latestPaste and LevelReference.looks_like_phiu(latestPaste):
	if latestPaste and should_use_clipboard_contents(latestPaste):
		OS.set_clipboard(latestPaste)
		self.ignore_next_text_change = true
		field.text = latestPaste


