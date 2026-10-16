module line_length

import math

const invalid_result = -1e300

// Repeated-step polyline length for the source demo curve sin(10*x).
@[export: 'line_length']
pub fn line_length(x_start f64, x_end f64, steps_value f64) f64 {
	if x_start != x_start || x_end != x_end || steps_value != steps_value ||
		x_start < -10.0 || x_start > 10.0 || x_end < -10.0 || x_end > 10.0 ||
		x_start > x_end || steps_value < 1.0 || steps_value > 10000.0 {
		return invalid_result
	}
	steps := int(steps_value)
	if f64(steps) != steps_value { return invalid_result }

	mut x1 := x_start
	mut fx1 := math.sin(10.0 * x_start)
	mut length := 0.0
	for _ in 0 .. steps {
		x2 := (x_end - x_start) / f64(steps) + x1
		fx2 := math.sin(10.0 * x2)
		dx := x2 - x1
		dy := fx2 - fx1
		length += math.sqrt(dx * dx + dy * dy)
		x1 = x2
		fx1 = fx2
	}
	return length
}
