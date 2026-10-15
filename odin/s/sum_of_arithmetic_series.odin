package sum_of_arithmetic_series

import "core:c"

INVALID_RESULT :: f64 = -1.0e300

@(export)
sum_of_arithmetic_series :: proc "c" (packed: [^]i64, length: c.size_t) -> f64 {
	if packed == nil || length != 3 do return INVALID_RESULT
	a := packed[0]
	d := packed[1]
	n := packed[2]
	if a < -1000 || a > 1000 || d < -1000 || d > 1000 || n < 1 || n > 1000 do return INVALID_RESULT
	result := n * (2 * a + (n - 1) * d) / 2
	return f64(result)
}
