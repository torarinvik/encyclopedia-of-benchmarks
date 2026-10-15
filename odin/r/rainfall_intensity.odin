package rainfall_intensity

import "core:c"
import "core:math"

@(export)
rainfall_intensity :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 6 do return -1.0e300
	k, a, b, c, period, duration := values[0], values[1], values[2], values[3], values[4], values[5]
	if k < 1 || k > 1000 || a < 1 || a > 3 || b < 1 || b > 100 || c < 1 || c > 3 || period < 1 || period > 100 || duration < 1 || duration > 1000 do return -1.0e300
	return (f64(k) * math.pow_f64(f64(period), f64(a))) / math.pow_f64(f64(duration + b), f64(c))
}
