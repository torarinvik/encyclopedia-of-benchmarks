package halley_root_finding

import "core:math"

@(export)
halley_root_finding :: proc "c" (initial_x, iteration_count: f64) -> f64 {
	if math.is_nan(initial_x) || math.is_nan(iteration_count) ||
		initial_x < 0.5 || initial_x > 2.0 || iteration_count < 0.0 ||
		iteration_count > 8.0 || math.floor_f64(iteration_count) != iteration_count {
		return -1.0
	}

	x := initial_x
	count := int(iteration_count)
	for i := 0; i < count; i += 1 {
		value := x*x*x - 2.0
		first := 3.0 * x*x
		second := 6.0 * x
		denominator := 2.0*first*first - value*second
		if denominator == 0.0 || math.is_nan(denominator) {
			return -1.0
		}
		x -= (2.0 * value * first) / denominator
		if math.is_nan(x) || x < 0.5 || x > 2.0 {
			return -1.0
		}
	}
	return x
}
