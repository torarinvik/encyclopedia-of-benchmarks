package bisection_2

import "core:c"

INVALID_RESULT :: -1.0e300
MAX_ENDPOINT_MILLI :: 100_000

equation :: proc "contextless" (x: f64) -> f64 { return 10.0 - x * x }

@(export)
bisection_2 :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length != 2 do return INVALID_RESULT
	left_milli, right_milli := input[0], input[1]
	if left_milli < -MAX_ENDPOINT_MILLI || left_milli > MAX_ENDPOINT_MILLI
		|| right_milli < -MAX_ENDPOINT_MILLI || right_milli > MAX_ENDPOINT_MILLI
		|| left_milli >= right_milli do return INVALID_RESULT
	a := f64(left_milli) / 1000.0
	b := f64(right_milli) / 1000.0
	if equation(a) * equation(b) >= 0.0 do return INVALID_RESULT
	c_value := a
	for (b - a) >= 0.01 {
		c_value = (a + b) / 2.0
		if equation(c_value) == 0.0 do break
		if equation(c_value) * equation(a) < 0.0 { b = c_value }
		else { a = c_value }
	}
	return c_value
}
