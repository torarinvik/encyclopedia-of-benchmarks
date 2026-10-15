package distance_formula

import "core:c"
import "core:math"

@(export)
distance_formula :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 4 do return -1.0e300
	for i in 0..<4 {
		if values[i] < -1000000 || values[i] > 1000000 do return -1.0e300
	}
	dx := f64(values[2] - values[0])
	dy := f64(values[3] - values[0])
	return math.sqrt(dx * dx + dy * dy)
}
