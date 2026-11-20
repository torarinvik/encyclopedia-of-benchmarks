module halley_root_finding

import math

@[export: 'halley_root_finding']
pub fn halley_root_finding(initial_x f64, iteration_count f64) f64 {
	if !math.is_finite(initial_x) || !math.is_finite(iteration_count) ||
		initial_x < 0.5 || initial_x > 2.0 || iteration_count < 0.0 ||
		iteration_count > 8.0 || math.floor(iteration_count) != iteration_count {
		return -1.0
	}

	mut x := initial_x
	count := int(iteration_count)
	for _ in 0 .. count {
		value := x * x * x - 2.0
		first := 3.0 * x * x
		second := 6.0 * x
		denominator := 2.0 * first * first - value * second
		if denominator == 0.0 || !math.is_finite(denominator) {
			return -1.0
		}
		x -= (2.0 * value * first) / denominator
		if !math.is_finite(x) {
			return -1.0
		}
	}
	return x
}
