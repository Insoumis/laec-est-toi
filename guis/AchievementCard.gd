extends Control

#const Achievement = preload("res://core/Achievement.gd")

onready var sprite = find_node("CardSprite")
onready var title_label = find_node('TitleLabel')
onready var description_label = find_node('DescriptionLabel')


func _ready():
	$AnimationPlayer.play("ShowBriefly")
	$PhiParticles.restart()
#	self.visible = true
	
	$TitleLabel.bbcode_text = \
		"[center][tornado radius=3 freq=2]%s[/tornado][/center]" \
		% tr('ACHIEVEMENT!')


#func from_achievement(achievement: Achievement):
func from_achievement(achievement):
	description_label.set_text(achievement.get_title_displayed())
	sprite.set_texture(achievement.image)

