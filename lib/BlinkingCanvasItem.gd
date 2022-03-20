extends ColorRect
class_name BlinkingColorRect


# Frequency of the whole blink loop
export var blinks_per_second := 1.0 setget set_bps, get_bps


func set_bps(value):
	assert(value > 0, "Negative blink frequencies are not allowed")
	if value <= 0:
		value = 1.0
	blinks_per_second = value
func get_bps():
	return blinks_per_second


var time_since_last_change := 0.0


func _process(delta):
	self.time_since_last_change += delta
	if self.time_since_last_change > 0.5 / self.blinks_per_second:
		blink()


func blink():
	self.time_since_last_change = 0.0
	self.visible = not self.visible
