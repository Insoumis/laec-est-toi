extends Resource
class_name AppSettingsPackerOptions


export var columns := 1
#export var column_gap_width := 32  # perhaps

export var row_height := 42
export var inner_gap_width := 16

# Tries to fill the available space
export var flex := true
# Only used when flex is false
export var label_width := 150
export var input_width := 243
# Only used when flex is true
export var text_to_button_ratio := 0.618
