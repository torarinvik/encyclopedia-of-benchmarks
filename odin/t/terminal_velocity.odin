package terminal_velocity

import "core:c"
import "core:math"

@(export)
terminal_velocity :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 4 do return -1.0e300
	mass := values[0]
	density := values[1]
	area := values[2]
	drag_coefficient := values[3]
	if mass < 1 || mass > 1000 || density < 1 || density > 1000 || area < 1 || area > 1000 || drag_coefficient < 1 || drag_coefficient > 1000 do return -1.0e300
	numerator := (2.0 * f64(mass)) * 9.80665
	denominator := (f64(density) * f64(area)) * f64(drag_coefficient)
	return math.sqrt(numerator / denominator)
}
