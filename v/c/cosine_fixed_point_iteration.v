module cosine_fixed_point_iteration

import math

@[export: 'cosine_fixed_point_iteration']
pub fn cosine_fixed_point_iteration(initial_input f64, source_n f64) f64 {
	if !math.is_finite(initial_input) || !math.is_finite(source_n) ||
		initial_input < 0.0 || initial_input > 2.0 || source_n < 0.0 || source_n > 64.0 ||
		math.floor(source_n) != source_n {
		return -1.0
	}

	mut value := initial_input
	updates := int(source_n) + 1
	for _ in 0 .. updates {
		value = 0.5 * (math.cos(value) + 2.0)
	}
	return value
}
