extends Reference
class_name Consumption

#   _____                                      _   _
#  / ____|                                    | | (_)
# | |     ___  _ __  ___ _   _ _ __ ___  _ __ | |_ _  ___  _ __
# | |    / _ \| '_ \/ __| | | | '_ ` _ \| '_ \| __| |/ _ \| '_ \
# | |___| (_) | | | \__ \ |_| | | | | | | |_) | |_| | (_) | | | |
#  \_____\___/|_| |_|___/\__,_|_| |_| |_| .__/ \__|_|\___/|_| |_|
#                                       | |
#                                       |_|
#
# This is not an abstraction of our society's behavior.
# This is used internally by the homebrewed (T_T) Sentence parser,
# in order to make backtracking easier.


var items_before := Array()
var items_consumed := Array()
var items_after := Array()


func _init(items:Array):
	# Not 100% certain we require duplication here,
	# but you know what they say about premature optimizations…
#	self.items_before = items
#	self.items_after = self.items_before
	self.items_before = items.duplicate()
	self.items_after = items.duplicate()


func has_happened() -> bool:
	return not self.items_consumed.empty()


func has_consumed_odd_amount() -> bool:
	return self.items_consumed.size() % 2 == 1


func happen_once() -> void:
	var item = self.items_after.pop_front()
	assert(item, "PoM, RmE — Peace of Mind, Remove me Eventually")
	if item:
		self.items_consumed.append(item)


func advance_by(consumption: Consumption) -> void:
	for item in consumption.items_consumed:
		assert(item == self.items_after[0])  # we don't want mixed consumptions
		happen_once()


# Kind of misleading and error-prone.  Prefer  advance_by()
func advance_to(consumption: Consumption) -> void:
	assert(self.items_before == consumption.items_before)
	self.items_after = consumption.items_after
	self.items_consumed = consumption.items_consumed

