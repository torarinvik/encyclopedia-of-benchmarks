package projectile_motion

import "core:c"
import "core:math"

@(export)
projectile_motion :: proc "c" (values: [^]f64, length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if values == nil || length != c.size_t(4) do return -1
	for i := 0; i < 4; i += 1 {
		if values[i] != values[i] do return -1
	}

	velocity, angle_degrees, height, gravity := values[0], values[1], values[2], values[3]
	if velocity < 0.0 || velocity > 1000.0 do return -1
	if angle_degrees < -180.0 || angle_degrees > 180.0 do return -1
	if height < 0.0 || height > 1000.0 do return -1
	if gravity < 0.1 || gravity > 20.0 do return -1

	angle_radians := angle_degrees / 180.0 * 3.14159265358979323846
	initial_vertical_velocity := velocity * math.sin(angle_radians)
	initial_horizontal_velocity := velocity * math.cos(angle_radians)
	total_time_of_flight := (initial_vertical_velocity +
		math.sqrt(initial_vertical_velocity * initial_vertical_velocity + 2.0 * gravity * height)) / gravity
	maximum_height := height
	if initial_vertical_velocity > 0.0 {
		height_gained := initial_vertical_velocity * initial_vertical_velocity / (2.0 * gravity)
		maximum_height = height + height_gained
	}
	horizontal_range := initial_horizontal_velocity * total_time_of_flight

	if output == nil || capacity < c.size_t(3) do return -2
	output[0], output[1], output[2] = total_time_of_flight, horizontal_range, maximum_height
	return 3
}
