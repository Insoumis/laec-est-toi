extends Resource
class_name Achievement


# Achievements are per-level.
# Each level may define a certain amount of achievements.
# They unlock when certain conditions are validated.
# Save each achievement to a file, in order to benefit from l10n.


# Conditions, such as
# - laec is you
# - not 1 monarc
# - 42 anar
# - anar on monarc
# - anar on monarc & anar is win
export var trigger_on_turn_if := ''
export var trigger_on_victory_if := ''

export(Texture) var image

export var snake_identifier := 'default_achievement'

# Automatically set by the level it is in to a translations key.
# Will look like:
# level.<LevelName>.<snake_identifier>.title
export var title := ""
# Local override, skipping I18N by taking precedence if set
export var title_custom := ""

func get_title_displayed() -> String:
	if self.title_custom != "":
		return self.title_custom
	if self.title != "":
		return tr(self.title)
	return "Achievement!"
################################################################################

# These should be moved elsewhere

func extract_conditions_strings(trigger_string: String) -> Array:
	var conditions := Array()
	
	for c in trigger_string.split('&'):
		conditions.append(
			c.strip_edges()
		)
	
	return conditions


func does_level_trigger_condition(level, condition_string) -> bool:
	if not condition_string:
		return false
	
	var condition = Condition.new()
	condition.from_string(condition_string)
	
	if condition.is_validated_by_level(level):
		return true
	
	return false


func does_level_trigger_trigger(level, trigger: String) -> bool:
	var conditions_strings = extract_conditions_strings(trigger)
	
	if not conditions_strings:
		return false
	
	for condition_string in conditions_strings:
		if not does_level_trigger_condition(level, condition_string):
			return false
	
	return true


################################################################################


func should_trigger_on_turn(level) -> bool:
	return does_level_trigger_trigger(level, self.trigger_on_turn_if)


func should_trigger_on_victory(level) -> bool:
	return does_level_trigger_trigger(level, self.trigger_on_victory_if)



