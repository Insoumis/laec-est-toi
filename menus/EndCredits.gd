extends Control



enum ROLES {
	ACE
	CODER
	TOOLS
#	GAME_MASTER
	GAME_DESIGNER
	LEVEL_DESIGNER
	MUSIC_COMPOSER
	MUSIC_PERFORMER
	GRAPHIC_DESIGNER
	TECHNICAL_ARTIST
	SOUND_DESIGNER
	ORGANIZER
	REVIEWER
	TESTER
	THANKS
	SPECIAL_THANKS
}


# By order of apparition, unless random is ON
var role_names = {
	ROLES.CODER : tr("Coder"),
	ROLES.TOOLS : tr("Tool developer"),
	ROLES.GAME_DESIGNER : tr("Game designer"),
	ROLES.LEVEL_DESIGNER : tr("Level designer"),
	ROLES.MUSIC_COMPOSER : tr("Music composer"),
	ROLES.MUSIC_PERFORMER : tr("Music performer"),
	ROLES.GRAPHIC_DESIGNER : tr("Graphic designer"),
	ROLES.TECHNICAL_ARTIST : tr("Technical artist"),
	ROLES.SOUND_DESIGNER : tr("Sound designer"),
	ROLES.ORGANIZER : tr("Organizer"),
	ROLES.ACE : tr("Ace"),
	ROLES.REVIEWER : tr("Reviewer"),
	ROLES.TESTER : tr("Tester"),
	ROLES.THANKS : tr("Thanks"),
	ROLES.SPECIAL_THANKS : tr("Special Thanks"),
}


var people := [
	{
		"name": "Fanelia",
		"roles": [ROLES.THANKS],
	},
	{
		"name": "Trollune",
		"roles": [ROLES.CODER, ROLES.TOOLS, ROLES.TECHNICAL_ARTIST, ROLES.LEVEL_DESIGNER, ROLES.GRAPHIC_DESIGNER, ROLES.GAME_DESIGNER],
	},
	{
		"name": "Precheurius",
		"roles": [ROLES.MUSIC_COMPOSER, ROLES.MUSIC_PERFORMER],
	},
	{
		"name": "Adrenesis",
		"roles": [ROLES.CODER, ROLES.TOOLS, ROLES.TECHNICAL_ARTIST],
	},
	{
		"name": "Miidnight",
		"roles": [ROLES.ORGANIZER, ROLES.LEVEL_DESIGNER],
	},
	{
		"name": "Dazo",
		"roles": [ROLES.LEVEL_DESIGNER],
	},
	{
		"name": "Bogoss69",
		"roles": [ROLES.THANKS],
	},
	{
		"name": "Roipoussiere",
		"roles": [ROLES.CODER, ROLES.GAME_DESIGNER],
	},
	{
		"name": "Karibou",
		"roles": [ROLES.THANKS],
	},
	{
		"name": "Zargett",
		"roles": [ROLES.LEVEL_DESIGNER],
	},
	{
		"name": "SpyBob",
		"roles": [ROLES.TESTER],
	},
	{
		"name": "Stheal",
		"roles": [ROLES.LEVEL_DESIGNER, ROLES.GAME_DESIGNER],
	},
	{
		"name": "Niwatori",
		"roles": [ROLES.GRAPHIC_DESIGNER],
	},
	{
		"name": "Lametyste",
		"roles": [ROLES.GRAPHIC_DESIGNER],
	},
	{
		"name": "IvanC",
		"roles": [ROLES.LEVEL_DESIGNER, ROLES.GAME_DESIGNER],
	},
	{
		"name": "AudreyH",
		"roles": [ROLES.GRAPHIC_DESIGNER],
	},
	{
		"name": "Gobz",
		"roles": [ROLES.THANKS],
	},
	{
		"name": "JeanSebastienBachOfficiel",
		"roles": [ROLES.TESTER],
	},
	{
		"name": "Saccharose4965",
		"roles": [ROLES.TESTER],
	},
	{
		"name": "Ista",
		"roles": [ROLES.ACE],
	}
]


export var scroll_speed := 50.0


# The scene (Start Menu) these End Credits redirect to once they're done
export(String, FILE, "*.tscn") var forward_scene_path: String


# Container (generated) for our generated nodes from the data above
var credits_holder: Control
var scroll_limit := 1000
# Computed and set during ready, from contents' size


func _process(delta):
	self.credits_holder.margin_top -= delta * self.scroll_speed
	if self.credits_holder.margin_top < -1 * self.scroll_limit:
		set_process(false)
		if self.forward_scene_path:
			Game.go_back_to_first()
			# todo
			#Game.go_back_to_scene_path(self.forward_scene_path)


func _ready():
	self.credits_holder = build_credit_controls(get_people_per_role())
	add_child(self.credits_holder)
	# Disable the nodes used as templates during building above
	$ProRoleLabel.visible = false
	$ProPersonLabel.visible = false
	# Position the credits below the screen (they'll scroll up)
	self.credits_holder.margin_top = get_viewport().size.y
	self.scroll_limit = self.credits_holder.find_node("CreditsVBox", true, false).rect_size.y


func get_people_per_role():
	var people_per_role = Dictionary()
	for role in ROLES.values():
		people_per_role[role] = Array()
	for person in self.people:
		for role in person.roles:
			people_per_role[role].append(person)
	return people_per_role


func build_credit_controls(people_per_role : Dictionary):
	var wrapper = Control.new()
	wrapper.name = "CreditsHolder"
	wrapper.anchor_top = 0.0
	wrapper.anchor_left = 0.0
	wrapper.anchor_right = 1.0
	wrapper.anchor_bottom = 1.0
	var credits_vbox = VBoxContainer.new()
	credits_vbox.name = "CreditsVBox"
	credits_vbox.anchor_top = 0.0
	credits_vbox.anchor_left = 0.0
	credits_vbox.anchor_right = 1.0
	credits_vbox.anchor_bottom = 1.0
	wrapper.add_child(credits_vbox)
	var roles = people_per_role.keys()
	randomize()
	roles.shuffle()
	for role in roles:
		if people_per_role[role].size() > 0:
			var role_label = $ProRoleLabel.duplicate()
			role_label.align = Label.ALIGN_CENTER
			var role_name = role_names[role].to_upper()
			role_label.text = "\n" + role_name + "\n"
			role_label.set("custom_fonts/font", $ProRoleLabel.get("custom_fonts/font"))
			credits_vbox.add_child(role_label)
			var role_people = people_per_role[role]
			role_people.shuffle()
			for person in role_people:
				var person_label = $ProPersonLabel.duplicate()
				person_label.align = Label.ALIGN_CENTER
				person_label.text = person.name
				person_label.set("custom_fonts/font", $ProPersonLabel.get("custom_fonts/font"))
				credits_vbox.add_child(person_label)
	return wrapper
	

