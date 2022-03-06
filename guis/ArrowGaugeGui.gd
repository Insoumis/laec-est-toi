extends Node2D


onready var arrow_filling := $ArrowFill


const amount_of_steps = 6.0  # see ArrowFill animation


func fill_gauge(amount_ratio:float):
	if 0.0 == amount_ratio:
		self.arrow_filling.visible = false
		return
	
	self.arrow_filling.visible = true
	var step = stepify(amount_ratio * amount_of_steps, 1)
	self.arrow_filling.animation = "gauge_%d" % step
