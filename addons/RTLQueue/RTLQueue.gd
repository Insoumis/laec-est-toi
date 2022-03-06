# Made by NetroScript, this plugin is usable under the MIT License
# For more information please visit Github: https://github.com/NetroScript/Godot-RTLQueue
class_name RTLQueue, "res://addons/RTLQueue/RTLQueue_icon.png"
extends ReferenceRect

# The Fonts should have the same heights
export var FONT : Font
export var FONT_MONO : Font
export var FONT_BOLD : Font
export var FONT_ITALICS : Font
export var FONT_BOLD_ITALICS : Font

# Currently not used for anything, but you can add custom behaviour like being able to view the previous page yourself
export onready var KEEP_PREVIOUS_QUEUE : bool = true

# How much space between lines
export onready var LINE_SEPARATION : int = 2

# If single pushed Strings should have a space between them. 
export var SPACE_BETWEEN_PARTS : bool = true

# If the Scrolling feature of GODOT should be used
export var ENABLE_SCROLLING : bool = false

# Input event name which triggers code speed up + showing the next "page" + ending the input
export var INTERACTION_EVENT : String = "pass"

# When holding the interaction key, how much the text / pause should be sped up
export var SPEED_INCREASE : float = 3

# If there is inline BBCode handle it correctly in append mode and bbcode_text mode
# If you want to use inline BBCode always have it surounded by spaces(those will be ignored later) f.e. add_text("[b] Fat text [/b]", 1) so it isn't clutched together with the word
export var HANDLE_INLINE_BBCODE : bool = true

# Characters (/words) where we don't wan't to add a space when stripping BBCode
export var PUNCTUATION : PoolStringArray = PoolStringArray([",", ";", ".", "!", "?"])

# Use append_bbcode instead of bbcode_text +=
# It then increases the amount of visible characters and adds every String directly
# Following Advantages: More efficient, Inline BBCODE possible
# Disadvantages: Unexpected Behaviour (especially considering line-break detection), breaks on resize (Although the script already adds the previous Content on resize again), if you add a tag previously (f.e. center) it will not count for further added Strings
export var USE_APPEND_BBCODE : bool = true

# If set, waits for user interaction key and then emits custom event
export var WAIT_FOR_INPUT_ON_FINISH : bool = true

onready var max_lines : int = 0
onready var label : RichTextLabel = RichTextLabel.new()
onready var previous_pages : Array = Array()
onready var done_queue : Array = Array()
onready var current_queue : Array = Array()
# Possible Queue types
enum {NORMAL_TEXT, IMAGE, OPERATOR, WAIT, CLEAR, WAIT_INPUT, NEW_LINE}
# Possible Queue Options
enum {OPTIONS_BOLD, OPTIONS_ITALICS, OPTIONS_UNDERLINED, OPTIONS_STRIKETHROUGH, OPTIONS_CODE, OPTIONS_RIGHT, OPTIONS_FILL, OPTIONS_CENTER, OPTIONS_IGNOREBBCODE}
# Used for time related stuff, to decide whether to do an action or not
var counter : float = 0
# If the Skript should be paused
var paused : bool = false
# used to decide if it is the start of a wait sequence
var queue_start : bool = true
# The "global" color which is the default color when an Queueitem doesn't have a color property
var last_active_color : Color = Color(1,1,1,1)
var waiting_for_next_page : bool = false
var check_newline : bool = false
# Currentvisible Lines only counts lines from autowrap, so we have to count newline characters (+ some tags which break the line) seperately
var current_newlines : int = 0
# Modify the current speed
var speed_up : float = 1
# Variable to keep track of if in the current step the number of lines increased
var last_lines : int = 1
# Variable to decide whether to prepend (and append) all the tags which are cut mid sentence
var tag_active : bool = true
# Variable to keep track of the current BBCode when using the appending mode
var bbcodebuffer : String = ""
# If a new string starts on a newline, don't prepend a space
var on_newline : bool = true
# When waiting for input
var waiting_for_input : bool = false
# List of those closing tags where we need to remove preceding whitespace
# Theoretically this also needs to be used for pure url, but because [url=] would break then, it is not included, if it is wanted feature I could image a add_url() function
const SPECIAL_TAGS : PoolStringArray = PoolStringArray(["[/img]"])
# Already parsed queues to decide if the element was just initialised
var parsedqueues : int = 0


# Signals

signal next_page() # When the next page starts to be displayed
signal queue_finished() # When the to do queue is empty
signal queue_finished_and_waited() # When the queue is empty and the player confirmed with space
signal event(event) # When a text has a custom event and it starts to be written
signal event_end(event) # When the text of a specific event finished writing
signal page_full() # When the script waits for the input event until continuing
signal queue_event(type) # When a specific Operator is used, currently only set color, pause
signal queue_wait_start() # When a wait (silence) starts
signal queue_wait_end() # When a wait (silence) ends
signal bbcode_cleared() # When the screen gets cleared
signal paused_until_input() # When an input Wait has been issued (like a page turn)
signal awaiting_input(type) # Everytime sent when an user interaction is sent, also when queue ended (waiting for close interaction f.e.), following 3 types: page_full, queue_finished, paused_until_input
signal got_input(type) # When Input was supplied, following 2 types: changed_page, finished_wait_for_input
signal pause() # When an operator in the queue paused it

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	set_physics_process(true)
	set_process_input(true)
	add_child(label)
	
	# For the appending mode, register the resize event, so the text can be added again
#warning-ignore:return_value_discarded
	get_tree().get_root().connect("size_changed", self, "_on_resize")
	
	# Initialize Variable stuff
	# You can call this again later when changing exportet settings in code
	init()


func init() -> void:
	
	# Setting font of the text
	if FONT != null:
		label.add_font_override("font", FONT)
		label.set("custom_fonts/normal_font", FONT)
	else:
		FONT = label.get_font("")
	if FONT_BOLD != null:
		label.set("custom_fonts/bold_font", FONT_BOLD)
	if FONT_ITALICS != null:
		label.set("custom_fonts/italics_font", FONT_ITALICS)
	if FONT_BOLD_ITALICS != null:
		label.set("custom_fonts/bold_italics_font", FONT_BOLD_ITALICS)
	if FONT_MONO != null:
		label.set("custom_fonts/mono_font", FONT_MONO)
	
	# Set further attributes which are needed
	label.bbcode_enabled = true
	label.anchor_bottom = 1.0
	label.anchor_right = 1.0
	label.anchor_left = 0.0
	label.anchor_top = 0.0
	label.margin_bottom = 0
	label.margin_left = 0
	label.margin_right = 0
	label.margin_top = 0
	
	# If scrolling is not enabled, we disable the scrollbar
	if not ENABLE_SCROLLING:
		label.scroll_active = false
		label.scroll_following = false
	else:
		label.scroll_active = true
		label.scroll_following = true
		# Scrolling goes right to bottom
		label.scroll_following = false
	
	# Get the maximum number of lines in the current container
	get_max_lines()

	# Set the line seperation
	label.set("custom_constants/line_separation", LINE_SEPARATION)
	
	# If we use the appending mode, we set visible characters to zero
	if USE_APPEND_BBCODE:
		label.visible_characters = 0
	else:
		label.visible_characters = -1


# Clear the current code, set newlines to zero and reset the text depending on mode
func clear(extendedclear : bool = false) -> void:
	
	current_newlines = 0
	on_newline = true
	if USE_APPEND_BBCODE:
		label.visible_characters = 0
	else:
		label.visible_characters = -1
		label.bbcode_text = ""
	if extendedclear:
		previous_pages.resize(0)
		done_queue.resize(0)
		waiting_for_input = false
		waiting_for_next_page = false
		parsedqueues = 0
		paused = false
		
	bbcodebuffer = ""
	label.clear()


func _input(event : InputEvent) -> void:
	
	# When our interaction event is clicked and we are waiting for the next page, we will go to the next page
	if event.is_action_pressed(INTERACTION_EVENT):
		if waiting_for_next_page:
			next_page()
			emit_signal("got_input", "changed_page")
		# When wait event continue with the data
		if waiting_for_input:
			if WAIT_FOR_INPUT_ON_FINISH and paused:
				waiting_for_input = false
				emit_signal("queue_finished_and_waited")
				emit_signal("got_input", "finished_wait_for_queueend")
			else:
				waiting_for_input = false
				emit_signal("got_input", "finished_wait_for_input")


func next_page() -> void:
	
	# Store current page in an object
	if KEEP_PREVIOUS_QUEUE:
		previous_pages.append(done_queue)
		# We make a copy instead of passing the reference
		previous_pages[previous_pages.size()-1].append(JSON.parse(JSON.print(current_queue[0])))
	# Empty the queue
	done_queue.resize(0)
	waiting_for_next_page = false
	if not ENABLE_SCROLLING:
		tag_active = true
		clear()
	else:
		# When scrolling is enabled we have to fake turning the next page
		current_newlines -= max_lines
	emit_signal("next_page")

func get_max_lines() -> int:
	
	# Wait for the object to render correclty
	yield(get_tree(), "idle_frame")
	max_lines = int(floor(get_size().y / ( FONT.get_height() + LINE_SEPARATION)))
	return max_lines


func _physics_process(delta : float) -> void:

	# If our interaction key is pressed we increase our speed variable
	if Input.is_action_pressed(INTERACTION_EVENT):
		if not waiting_for_next_page:
			speed_up = SPEED_INCREASE
	else:
		speed_up = 1

	if not paused and not waiting_for_next_page and not waiting_for_input:
		if current_queue.size() == 0:
			if parsedqueues > 0:
				emit_signal("queue_finished")
				paused = true
				if WAIT_FOR_INPUT_ON_FINISH:
					waiting_for_input = true
					emit_signal("awaiting_input", "queue_finished")
		else:
			var currentitem : Queueoptions = current_queue[0]
			match currentitem.type:
				NORMAL_TEXT:
					# Increase the speed by speed_up
					counter+=delta*speed_up
					
					# used to decide if all words are written
					var finished : bool = false

					# This is only -1 on the first initialisation so we do our setup stuff here
					if currentitem.currentword == -1:
						
						# Add a new space if enabled
						if SPACE_BETWEEN_PARTS and not on_newline:
							_append_text(" ")
							# In append mode we also have to show that
							if USE_APPEND_BBCODE:
								label.visible_characters+=1
						
						# Reset newline because now a word will be written
						on_newline = false
						
						# Add the spaces again which were lost while splitting the string
						var i : int = 1
						for word in currentitem.wordlist:
							# If the word is not the last, or doesn't seems to be BBCode add a space to recreate the original string 
							if not (HANDLE_INLINE_BBCODE and word.length() > 0 and word[0]=="[" and not flag_enabled(currentitem.flags, OPTIONS_IGNOREBBCODE) and word[word.length()-1] == "]"):
								if i != currentitem.wordlist.size():
									currentitem.wordlist[i-1] += " "
							# If we "strip" tags and punctiation is following, we don't want to add a space
							else:
								if i-2 > 0 and currentitem.wordlist.size() >= i and (currentitem.wordlist[i] in PUNCTUATION) and currentitem.wordlist[i-2][ currentitem.wordlist[i-2].length()-1] == " ":
									currentitem.wordlist[i-2] = currentitem.wordlist[i-2].left(currentitem.wordlist[i-2].length()-1)
								elif i-2 > 0 and word in SPECIAL_TAGS:
									currentitem.wordlist[i-2] = currentitem.wordlist[i-2].left(currentitem.wordlist[i-2].length()-1)
							
							i+=1
						
						# It is the start of the query, so in any case the tags like color or bold need to be appended
						tag_active = true
						
						# If a custom event is set, we emit a signal
						if currentitem.event != "":
							emit_signal("event", currentitem.event)
						
						# Set the current word which is shown to the first one
						currentitem.currentword = 0

					# If a new query or a new page we need to write all tags
					if tag_active:
						
						# Tag text, all in 1 string, so we do less changes (so it needs to be parsed less often)
						var outtext : String = ""
						
						# If there is a custom color, use it, otherwise use the "global" color
						if not (currentitem.color.a == 0 and currentitem.color.r == 0 and currentitem.color.g == 1 and currentitem.color.b == 0):
							outtext += "[color=#"+currentitem.color.to_html()+"]"
						else:
							outtext += "[color=#"+last_active_color.to_html()+"]"
							
						# Variables to store all flags like bold / centered
						var flags : String = ""
						var endingflags : String = ""
						for f in queueoptionsflagstotags(currentitem.flags):
							var flag : String = f as String
							flags += "["+flag+"]"
							endingflags = "[/"+flag+"]"+endingflags
							
							# The following tags will break into a newline (if not at the start of the RTL) so we add to newlines
							if flag == "fill" or flag == "right" or flag == "center" or flag == "code":
								current_newlines += 1

						# If we are in append mode we already add the entire query string with the opening and closing tags, otherwise we just add the opening tags
						if USE_APPEND_BBCODE:
							outtext += flags
							
							var i : int = currentitem.currentword
							while i < currentitem.wordlist.size():
								outtext += currentitem.wordlist[i]
								i+=1
							
							outtext += endingflags
							_append_text(outtext)
						else:
							_append_text(outtext+flags)
							
						# Tags have been added
						tag_active = false

					while counter-(1/currentitem.time) > 0:
						
						# If the current word exists do all the word handling code
						if currentitem.wordlist.size() > currentitem.currentword:
							
							# Current word
							var word : String = currentitem.wordlist[currentitem.currentword]
							
							# Might be obsolete because space is added
							if word == "":
								currentitem.currentword+=1
								if currentitem.wordlist.size() <= currentitem.currentword:
									finished = true
							elif HANDLE_INLINE_BBCODE and word[0]=="[" and not flag_enabled(currentitem.flags, OPTIONS_IGNOREBBCODE) and word[word.length()-1] == "]":
								
								if word=="[img]":
									if not USE_APPEND_BBCODE:
										_append_text(word)
										if currentitem.wordlist.size() > currentitem.currentword + 2:
											_append_text(currentitem.wordlist[currentitem.currentword + 1]+currentitem.wordlist[currentitem.currentword + 2])
									else:
										label.visible_characters += 1
										
									currentitem.currentword+=3
									
								else:
								
									if not USE_APPEND_BBCODE:
										_append_text(word)
										
									currentitem.currentword+=1
							else:
								# If the current word is new, we check if the line breaks if we add the current word
								if check_newline:
									
									#print("Maximal Lines: " + str(max_lines) + " | Current Lines: " + str(label.get_visible_line_count() + current_newlines))
									# Only do the checking if the current line is already the max lines (because a change from f.e. line 1 to 2 with 3 max lines doesn't matter)
									if label.get_visible_line_count() + current_newlines >= max_lines:
										# If Using Append mode just make all characters visible, otherwise add the word to the BBCode
										if USE_APPEND_BBCODE:
											label.visible_characters += word.length()
										else:
											_append_text(word)
										# Wait for it to render correctly
										yield(get_tree(), "idle_frame")
										#print("New Max Lines: " + str(label.get_visible_line_count() + current_newlines))
										# If it now exceeds the maximal lines
										if label.get_visible_line_count() + current_newlines > max_lines:
											# Fake Page not being full by decreasing current newlines
											if ENABLE_SCROLLING:
												current_newlines -= 1
											# Emit page full signal and wait for the next page
											else:
												waiting_for_next_page = true
												emit_signal("awaiting_input", "page_full")
												emit_signal("page_full")
												#print("We have to open the next page")
										# After the check eighter reduce visible characters again or remove the word from the box
										if USE_APPEND_BBCODE:
											label.visible_characters -= word.length()
										else:
											label.bbcode_text = label.get_bbcode().left(label.get_bbcode().length()-word.length())
										check_newline = false
									else:
										check_newline = false
	
								# If the current word wouldn't break the line to a new page
								if not waiting_for_next_page:
									# If enough time passed to display the character
									if counter > 1/currentitem.time:
										# Remove the time for one character, in the case of lag the counter doesn't need to count up again, but would do 1 char on each tick
										counter -= 1/currentitem.time
										
										# Keep track if the line number increased, if so set newline to true
										# This might not be needed at all because on_newline is set in add_newline and chance of a query string ending perfectly on a line is really low
										if label.get_visible_line_count() + current_newlines > last_lines:
											last_lines = label.get_visible_line_count()  + current_newlines
											on_newline = true
										else:
											on_newline = false
											
										# If in append mode increase the currently shown characters, otherwise add it to the bbcode text
										if USE_APPEND_BBCODE:
											label.visible_characters += 1
										else:
											_append_text(word[currentitem.currentwordindex])
										
										# Increase the character of the current word
										currentitem.currentwordindex+=1
										# If current characters index is longer than the word switch to character index 0 on the next word an enable checking for newline again
										if currentitem.currentwordindex >= word.length():
											currentitem.currentwordindex = 0
											currentitem.currentword+=1
											check_newline = true
								else:
									break

						# If this word was the last word in the list, set finished to true
						if currentitem.wordlist.size() <= currentitem.currentword:
							finished = true
						
						# Considering I have no idea if it is passed by reference or copy, we set the current_queue item to the modiefied currentitem
						current_queue[0] = currentitem
						
						# Code when the current text was finished
						if finished:
							# If a custom event is set, we emit an end signal
							if currentitem.event != "":
								emit_signal("event_end", currentitem.event)
							
							# If we do not use the append mode, we now have to close all our tags
							if not USE_APPEND_BBCODE:
								var closingflags : String = ""
								for flag in queueoptionsflagstotags(currentitem.flags).invert():
									closingflags += "[/"+flag+"]"
								_append_text(closingflags+"[/color]")
							# Reset our counter
							counter = 0
							
							# Removing the task from the working queue
							done_queue.append(current_queue.pop_front())
							parsedqueues+=1

				OPERATOR:
					# If we change the color, set the current active color to the new one
					if currentitem.event == "colorchange":
						last_active_color = currentitem.color
					# If it is a pause, pause the execution
					elif currentitem.event == "pause":
						paused = true
						emit_signal("pause")
						
					# Emit the signal of the operator
					emit_signal("queue_event", currentitem.event)
					# Removing the task from the working queue
					done_queue.append(current_queue.pop_front())
					parsedqueues+=1

				NEW_LINE:
					var newlines : String = ""
					for i in range(currentitem.repeat):
						newlines+="\n"
					# Append n newlines in the current text
					_append_text(newlines)
					# Increase our amount of newlines
					current_newlines+=currentitem.repeat
					# Removing the task from the working queue
					done_queue.append(current_queue.pop_front())
					parsedqueues+=1
					on_newline = true

				WAIT:
					counter+=delta*speed_up
					# If this is called for the first time emit wait start
					if queue_start:
						queue_start = false
						emit_signal("queue_wait_start")
					# If the wait time is over emit wait end and move on to the next task
					if counter > currentitem.time:
						queue_start = true
						emit_signal("queue_wait_end")
						counter = 0
						# Removing the task from the working queue
						done_queue.append(current_queue.pop_front())
						parsedqueues+=1

				CLEAR:
					clear()
					emit_signal("bbcode_cleared")
					# Removing the task from the working queue
					done_queue.append(current_queue.pop_front())
					parsedqueues+=1

				WAIT_INPUT:
					waiting_for_input = true
					emit_signal("paused_until_input")
					emit_signal("awaiting_input", "paused_until_input")
					# Removing the task from the working queue
					done_queue.append(current_queue.pop_front())
					parsedqueues+=1

				IMAGE:
					counter+=delta*speed_up
					if counter > currentitem.time:
						
						# Add the image to the text box
						_append_text(currentitem.wordlist[0])
						# If it is Append Mode we have to increase the shown characters
						if USE_APPEND_BBCODE:
							label.visible_characters += 1
						
						# If this would be more than the maximal lines on line break 
						if last_lines >= max_lines:
							# Wait for it to render correctly
							yield(get_tree(), "idle_frame")
							# If more than maximal lines wait for the next page, remove the added image (or make it invisible) and prevent removing this image from the pending queue
							if label.get_visible_line_count() + current_newlines > last_lines:
								waiting_for_next_page = true
								print("Image would break line")
								if USE_APPEND_BBCODE:
									label.visible_characters -= 1
								else:
									label.bbcode_text = label.get_bbcode().left(label.get_bbcode().length()-currentitem.wordlist[0].length())
								return
							
						counter = 0
						# Removing the task from the working queue
						done_queue.append(current_queue.pop_front())
						parsedqueues+=1


# Add text to the RichTextLabel
# Needs a text string and how many characters per second should be displayed
# Optionally a dictionary can be supplied which can have the options in the settings variable
func add_text(text : String, characterpersecond : float, event : String = "", options : PoolIntArray = PoolIntArray(), color : Color = Color(0,1,0,0)) -> void:

	# Remove a newline character, otherwise it wouldn't be kept track of and the code for pages would break
	text = text.replacen("\n", "")

	var queueoptions : Queueoptions = Queueoptions.new(NORMAL_TEXT)
	queueoptions.wordlist = PoolStringArray(text.split(" "))
	queueoptions.time = characterpersecond
	queueoptions.event = event
	queueoptions.flags = array_to_queueoptionsflags(options)
	queueoptions.color = color
	
	current_queue.append(queueoptions)



# Push a wait time in seconds
func add_wait(time : float) -> void:
	
	var queueoptions : Queueoptions = Queueoptions.new(WAIT)
	queueoptions.time = time
	
	current_queue.append(queueoptions)


func add_wait_for_interaction() -> void:
	
	var queueoptions : Queueoptions = Queueoptions.new(WAIT_INPUT)
	
	current_queue.append(queueoptions)


func add_clear() -> void:
	
	var queueoptions : Queueoptions = Queueoptions.new(CLEAR)
	
	current_queue.append(queueoptions)


# Add an image in the textbox, optional delay until it is added in seconds
# The intended way is to use images which are as high as the line, fix it yourself if you are using bigger images
func add_image(imagepath : String, time : float = 0.0) -> void:
	
	var queueoptions : Queueoptions = Queueoptions.new(IMAGE)
	queueoptions.time = time
	queueoptions.wordlist = PoolStringArray(["[img]"+imagepath+"[/img]"])
	
	current_queue.append(queueoptions)


# Add a linebreak
func add_newline(amount : int = 1) -> void:
	
	var queueoptions : Queueoptions = Queueoptions.new(NEW_LINE)
	queueoptions.repeat = amount
	
	current_queue.append(queueoptions)


# Add a pause, which has to be programatically be set to false
func add_pause() -> void:
	
	var queueoptions : Queueoptions = Queueoptions.new(OPERATOR)
	queueoptions.event = "pause"
	
	current_queue.append(queueoptions)


# Set the global color starting from this item
func set_color(color : Color) -> void:
	
	var queueoptions : Queueoptions = Queueoptions.new(OPERATOR)
	queueoptions.event = "colorchange"
	queueoptions.color = color
	
	current_queue.append(queueoptions)


# Append text differently depending on the current mode
func _append_text(text : String) -> void:
	
	if USE_APPEND_BBCODE:
		bbcodebuffer += text
#warning-ignore:return_value_discarded
		label.append_bbcode(text)
	else:
		label.bbcode_text += text


# Our resize event
func _on_resize() -> void:
	
	if USE_APPEND_BBCODE:
		label.clear()
#warning-ignore:return_value_discarded
		label.append_bbcode(bbcodebuffer)


# Using a queueoptions object with all possible options to enable better code completion (enjoy the green numbers on the left side)
class Queueoptions:
	
	var type : int
	var color : Color = Color(0,1,0,0)
	var time : float = 0
	var event : String = ""
	var repeat : int = 0
	var flags : int = 0
	var wordlist : PoolStringArray = PoolStringArray()
	var currentword : int = -1
	var currentwordindex : int = 0
	
	func _init(type : int):
		self.type = type


# Functions to simulate bit flags, so we just store a single integer in the Queueoptions class
func flag_enabled(flags : int, index : int) -> bool:
	return flags & (1 << index) != 0


func enable_flag(flags : int, index : int) -> int:
	return flags | (1 << index)


func disable_flag(flags : int, index : int) -> int:
	return flags & ~(1 << index)


# Functionsto quickly turn an array with the OPTIONS_ enum into the correct flags for the Queueoptions class
func array_to_queueoptionsflags(array : PoolIntArray) -> int:
	
	var flags : int = 0
	var possibleoptions : PoolIntArray = PoolIntArray([OPTIONS_BOLD, OPTIONS_ITALICS, OPTIONS_UNDERLINED, OPTIONS_STRIKETHROUGH, OPTIONS_CODE, OPTIONS_RIGHT, OPTIONS_FILL, OPTIONS_CENTER, OPTIONS_IGNOREBBCODE])
	
	var i : int = 0
	for x in possibleoptions:
		var option : int = possibleoptions[i]
		if option in array:
			flags = enable_flag(flags, i)
		i+= 1

	return flags


# Function to quickly turn Queueoptions flags into the correct tags
func queueoptionsflagstotags(flags : int) -> PoolStringArray:
	
	var possibletags: PoolStringArray = PoolStringArray(["b", "i", "u", "s", "code", "right", "fill", "center"])
	
	var i : int = possibletags.size() - 1
	
	while i > -1:
		if not flag_enabled(flags, i):
			possibletags.remove(i)
		i -= 1

	return possibletags
