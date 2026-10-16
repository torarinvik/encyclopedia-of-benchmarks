package gamma

import "core:math"

INVALID_RESULT :: -1.0e300

gamma_recursive_impl :: proc(num: f64) -> f64 {
	if num == 0.5 do return math.sqrt(3.14159265358979323846)
	if num == 1.0 do return 1.0
	return (num - 1.0) * gamma_recursive_impl(num - 1.0)
}

@(export)
gamma_recursive :: proc "c" (num: f64) -> f64 {
	if num < 0.5 || num > 20.0 || num * 2.0 != math.floor(num * 2.0) do return INVALID_RESULT
	return gamma_recursive_impl(num)
}
