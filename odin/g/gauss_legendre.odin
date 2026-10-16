package gauss_legendre

import "core:math"

MAX_ITERATIONS :: 8
INVALID_RESULT :: -1.0e300

pi_after_iterations :: proc(iterations: int) -> f64 {
	a := 1.0
	b := math.sqrt(0.5)
	t := 0.25
	p := 1.0
	for index := 0; index < iterations; index += 1 {
		next_a := (a + b) / 2.0
		next_b := math.sqrt(a * b)
		difference := a - next_a
		next_t := t - p * difference * difference
		next_p := 2.0 * p
		a = next_a
		b = next_b
		t = next_t
		p = next_p
	}
	sum := a + b
	return sum * sum / (4.0 * t)
}

@(export)
gauss_legendre :: proc "c" (iterations_value: f64) -> f64 {
	if !(iterations_value >= 0.0 && iterations_value <= f64(MAX_ITERATIONS)) do return INVALID_RESULT
	if iterations_value != f64(int(iterations_value)) do return INVALID_RESULT
	return pi_after_iterations(int(iterations_value))
}
