package modified_newton_multiple_root

import "core:math"

@(export)
modified_newton_multiple_root :: proc "c" (initial_x, iteration_count: f64) -> f64 {
	if math.is_nan(initial_x) || math.is_nan(iteration_count) ||
		initial_x < 1.0 || initial_x > 2.0 || iteration_count < 0.0 ||
		iteration_count > 8.0 || math.floor_f64(iteration_count) != iteration_count {
		return -1.0
	}

	x := initial_x
	count := int(iteration_count)
	for i := 0; i < count; i += 1 {
		if x == 1.0 {
			break
		}
		offset := x - 1.0
		value := offset * offset * (x + 2.0)
		derivative := 3.0 * offset * (x + 1.0)
		if derivative == 0.0 || math.is_nan(derivative) {
			return -1.0
		}
		x -= 2.0 * (value / derivative)
		if math.is_nan(x) || x < 1.0 || x > 2.0 {
			return -1.0
		}
	}
	return x
}
