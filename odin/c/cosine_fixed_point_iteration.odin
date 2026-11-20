package cosine_fixed_point_iteration

import "core:math"

@(export)
cosine_fixed_point_iteration :: proc "c" (initial_input, source_n: f64) -> f64 {
	if math.is_nan(initial_input) || math.is_nan(source_n) ||
		initial_input < 0.0 || initial_input > 2.0 || source_n < 0.0 || source_n > 64.0 ||
		math.floor_f64(source_n) != source_n {
		return -1.0
	}

	value := initial_input
	updates := int(source_n) + 1
	for iteration := 0; iteration < updates; iteration += 1 {
		value = 0.5 * (math.cos(value) + 2.0)
	}
	return value
}
