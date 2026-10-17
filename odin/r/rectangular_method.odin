package rectangular_method

import "core:c"
import "core:math"

INVALID_RESULT :: f64(-1.0e300)

integrand :: proc(x: f64) -> f64 {
	return (math.exp_f64(x) / 2.0) * (math.cos_f64(x) - math.sin_f64(x))
}

@(export)
rectangular_method :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 4 do return INVALID_RESULT
	a_quarters, b_quarters := values[0], values[1]
	intervals, rule := values[2], values[3]
	if a_quarters < -64 || a_quarters >= b_quarters || b_quarters > 64 ||
		intervals < 1 || intervals > 64 do return INVALID_RESULT
	if (b_quarters-a_quarters) % intervals != 0 || (rule != 0 && rule != 1) do return INVALID_RESULT

	a := f64(a_quarters) / 4.0
	b := f64(b_quarters) / 4.0
	step := (b - a) / f64(intervals)
	x, total := a, f64(0.0)
	for index := i64(0); index < intervals; index += 1 {
		if rule == 0 {
			total += integrand(x) * step
			x += step
		} else {
			x += step
			total += integrand(x) * step
		}
	}
	return total
}
