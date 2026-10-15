package escape_velocity

import "core:c"
import "core:math"

round_three_even :: proc(value: f64) -> f64 {
	scaled := value * 1000.0
	lower := math.floor(scaled)
	rounded := i64(lower)
	midpoint := lower + 0.5
	exact_side := math.fused_mul_add(value, 1000.0, -midpoint)
	if exact_side > 0.0 || (exact_side == 0.0 && rounded % 2 != 0) do rounded += 1
	return f64(rounded) / 1000.0
}

@(export)
escape_velocity :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 2 do return -1.0e300
	mass, radius := values[0], values[1]
	if mass < 0 || mass > 1000000000000000 || radius < 1 || radius > 1000000000 do return -1.0e300
	velocity := math.sqrt(2.0 * 6.67430e-11 * f64(mass) / f64(radius))
	return round_three_even(velocity)
}
