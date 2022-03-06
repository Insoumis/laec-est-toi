extends Resource
class_name SpirographResource



export(Gradient) var color_gradient


export var animation_speed := 1.0
export var draw_speed := 2.0
export var amount_of_samples := pow(2, 13)  # maximum 2 ** 13
export var amount_of_circles := 4  # minimum 0 (but why would you even…), max ?.
export var initial_center := Vector2(0.5, 0.5)  # fraction of viewport


export var circle_00_radius := 20.00  # % of viewport
export var circle_00_radius_variation := 0.000  # % of viewport
export var circle_00_radius_frequency := 0.016  # loops per second
export var circle_00_phase := 0.000  # fraction of circle
export var circle_00_phase_variation := 0.000  # fraction of circle
export var circle_00_phase_frequency := 0.016  # loops per second
export var circle_00_speed := 0.100  # turns/s
export var circle_00_speed_variation := 0.000  # turns/s
export var circle_00_speed_frequency := 0.016  # loops per second


export var circle_01_radius := 0.0  # % of viewport
export var circle_01_radius_variation := 0.000  # % of viewport
export var circle_01_radius_frequency := 0.016  # loops per second
export var circle_01_phase := 0.00  # fraction of circle
export var circle_01_phase_variation := 0.000  # fraction of circle
export var circle_01_phase_frequency := 0.016  # loops per second
export var circle_01_speed := 0.2  # turns/s
export var circle_01_speed_variation := 0.000  # turns/s
export var circle_01_speed_frequency := 0.016  # loops per second


export var circle_02_radius := 0.0  # % of viewport
export var circle_02_radius_variation := 0.00  # % of viewport
export var circle_02_radius_frequency := 0.016  # loops per second
export var circle_02_phase := 0.00  # fraction of circle
export var circle_02_phase_variation := 0.00  # fraction of circle
export var circle_02_phase_frequency := 0.016  # loops per second
export var circle_02_speed := 0.3  # turns/s
export var circle_02_speed_variation := 0.00  # turns/s
export var circle_02_speed_frequency := 0.016  # loops per second


export var circle_03_radius := 0.0  # % of viewport
export var circle_03_radius_variation := 0.00  # % of viewport
export var circle_03_radius_frequency := 0.016  # loops per second
export var circle_03_phase := 0.00  # fraction of circle
export var circle_03_phase_variation := 0.00  # fraction of circle
export var circle_03_phase_frequency := 0.016  # loops per second
export var circle_03_speed := 0.3  # turns/s
export var circle_03_speed_variation := 0.00  # turns/s
export var circle_03_speed_frequency := 0.016  # loops per second


# …

func clear():
	for i in range(amount_of_circles):
		for property in ["radius", "phase", "speed"]:
			for suffix in ["", "_variation", "_frequency"]:
				var property_name = "%s%s" % [property, suffix]
				self.set("circle_%02d_%s" % [i, property_name], 0.0)
