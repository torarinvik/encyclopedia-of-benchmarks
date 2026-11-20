module modified_newton_multiple_root

import math

@[export: 'modified_newton_multiple_root']
pub fn modified_newton_multiple_root(initial_x f64, iteration_count f64) f64 {
	if !math.is_finite(initial_x) || !math.is_finite(iteration_count) ||
		initial_x < 1.0 || initial_x > 2.0 || iteration_count < 0.0 ||
		iteration_count > 8.0 || math.floor(iteration_count) != iteration_count {
		return -1.0
	}

	mut x := initial_x
	count := int(iteration_count)
	for _ in 0 .. count {
		if x == 1.0 {
			break
		}
		offset := x - 1.0
		value := offset * offset * (x + 2.0)
		derivative := 3.0 * offset * (x + 1.0)
		if derivative == 0.0 || !math.is_finite(derivative) {
			return -1.0
		}
		x -= 2.0 * (value / derivative)
		if !math.is_finite(x) || x < 1.0 || x > 2.0 {
			return -1.0
		}
	}
	return x
}
