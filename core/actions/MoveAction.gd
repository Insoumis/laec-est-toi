extends Action
class_name MoveAction


# Inject this when you create a new MoveAction:
# var action = MoveAction.new(Directions.LEFT)
var direction = Directions.RIGHT


func _init(target_direction):
	assert(Directions.AVAILABLE.has(target_direction))
	self.direction = target_direction


func to_string() -> String:
	assert(Directions.CHARACTERS.keys().has(self.direction))
	return Directions.CHARACTERS[self.direction]
