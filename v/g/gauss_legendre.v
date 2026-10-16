module gauss_legendre

import math

const max_iterations = 8.0
const invalid_result = -1.0e300

fn pi_after_iterations(iterations int) f64 {
	mut a := 1.0
	mut b := math.sqrt(0.5)
	mut t := 0.25
	mut p := 1.0
	for _ in 0 .. iterations {
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

@[export: 'gauss_legendre']
pub fn gauss_legendre(iterations_value f64) f64 {
	if !(iterations_value >= 0.0 && iterations_value <= max_iterations) { return invalid_result }
	if iterations_value != f64(int(iterations_value)) { return invalid_result }
	return pi_after_iterations(int(iterations_value))
}
