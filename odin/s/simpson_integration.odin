package simpson_integration

import "core:c"
import "core:math"

INVALID_RESULT :: f64(-1.0e300)
MAX_ENDPOINT_MICRO :: i64(10000000)

integrand :: proc(x: f64) -> f64 {
	return math.exp_f64(-x) * (4.0 - math.pow_f64(x, 2.0))
}

@(export)
simpson_integration :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 3 do return INVALID_RESULT
	intervals, a_micro, b_micro := values[0], values[1], values[2]
	if intervals < 2 || intervals > 128 || intervals % 2 != 0 ||
		a_micro < -MAX_ENDPOINT_MICRO || a_micro > MAX_ENDPOINT_MICRO ||
		b_micro < -MAX_ENDPOINT_MICRO || b_micro > MAX_ENDPOINT_MICRO || a_micro > b_micro do return INVALID_RESULT
	a := f64(a_micro) / 1000000.0
	b := f64(b_micro) / 1000000.0
	if a == b do return 0.0
	h := (b - a) / f64(intervals)
	xi, total := a, f64(0.0)
	for i := i64(0); i <= intervals; i += 1 {
		sample := integrand(xi)
		if i == 0 || i == intervals {
			total += sample
		} else if i % 2 != 0 {
			total += 4.0 * sample
		} else {
			total += 2.0 * sample
		}
		xi += h
	}
	return (h / 3.0) * total
}
