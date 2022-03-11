extends Node


export var measure_turn_spending := false


var level


func _ready():
	setup()


func setup():
	self.level = find_parent_level()
	if self.measure_turn_spending:
		var _c1 = self.level.connect("turn_spending_started", self, "on_turn_spending_started")
		var _c2 = self.level.connect("turn_spending_ended", self, "on_turn_spending_ended")


func find_parent_level():
	var Level = load("res://addons/laec-is-you/entity/Level.gd")
	var p = get_parent()
	while p:
		if p is Level:
			return p
		p = p.get_parent()
	return null


func on_turn_spending_started():
	if not self.measure_turn_spending:
		return
	Chronometer.start("turn_spending")


func on_turn_spending_ended():
	if not self.measure_turn_spending:
		return
	var duration := Chronometer.stop("turn_spending", true)
	if duration > 0.015:
		pass  # todo: perhaps print?
	print(tr("Turn spending took %fs") % duration)

