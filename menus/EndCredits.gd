extends Control


# Développement
# Pixels
# Musique
# Niveaux
# 
# Famille

enum ROLES {
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

var role_names = {
	ROLES.CODER : tr("Coder"),
	ROLES.TOOLS : tr("Tool developper"),
	ROLES.GAME_DESIGNER : tr("Game designer"),
	ROLES.LEVEL_DESIGNER : tr("Level designer"),
	ROLES.MUSIC_COMPOSER : tr("Music composer"),
	ROLES.MUSIC_PERFORMER : tr("Music performer"),
	ROLES.GRAPHIC_DESIGNER : tr("Graphic designer"),
	ROLES.TECHNICAL_ARTIST : tr("Technical artist"),
	ROLES.SOUND_DESIGNER : tr("Sound designer"),
	ROLES.ORGANIZER : tr("Organizer"),
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
		"roles": [ROLES.CODER],
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
		"roles": [ROLES.CODER],
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
		"roles": [ROLES.LEVEL_DESIGNER],
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

]


var pages := [
	{
		'title': "",
		'text': "",
	},
]

var credits_holder

func _process(delta):
	credits_holder.margin_top -= delta * 50.0

func _ready():
	credits_holder = build_credit_controls(get_people_per_role())
	add_child(credits_holder)
	$ProRoleLabel.visible = false
	$ProPersonLabel.visible = false
	credits_holder.margin_top = 800.0

func get_people_per_role():
	var people_per_role = Dictionary()
	for role in ROLES.values():
		people_per_role[role] = Array()
	for person in people:
		for role in person.roles:
			people_per_role[role].append(person)
	return people_per_role

func build_credit_controls(people_per_role : Dictionary):
	var credits_holder = Control.new()
	credits_holder.anchor_top = 0.0
	credits_holder.anchor_left = 0.0
	credits_holder.anchor_right = 1.0
	credits_holder.anchor_bottom = 1.0
	var credits_vbox = VBoxContainer.new()
	credits_vbox.anchor_top = 0.0
	credits_vbox.anchor_left = 0.0
	credits_vbox.anchor_right = 1.0
	credits_vbox.anchor_bottom = 1.0
	credits_holder.add_child(credits_vbox)
	for role in people_per_role.keys():
		if people_per_role[role].size() > 0:
			var role_label = $ProRoleLabel.duplicate()
			role_label.align = Label.ALIGN_CENTER
			var role_name = role_names[role].to_upper()
			print(role_name)
			role_label.text = "\n" + role_name + "\n"
			role_label.set("custom_fonts/font", $ProRoleLabel.get("custom_fonts/font"))
			credits_vbox.add_child(role_label)
			for person in people_per_role[role]:
				var person_label = $ProPersonLabel.duplicate()
				person_label.align = Label.ALIGN_CENTER
				person_label.text = person.name
				person_label.set("custom_fonts/font", $ProPersonLabel.get("custom_fonts/font"))
				credits_vbox.add_child(person_label)
	return credits_holder
	

