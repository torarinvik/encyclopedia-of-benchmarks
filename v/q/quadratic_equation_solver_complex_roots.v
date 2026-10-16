module quadratic_equation_solver_complex_roots

import math

const coefficient_limit = i64(1_000_000)
const invalid_result = -1.0e300

@[export: 'quadratic_equation_solver_complex_roots']
pub fn quadratic_equation_solver_complex_roots(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 4 { return invalid_result }
	a, b, c, component := unsafe { values[0] }, unsafe { values[1] }, unsafe { values[2] }, unsafe { values[3] }
	if a == 0 || a < -coefficient_limit || a > coefficient_limit ||
		b < -coefficient_limit || b > coefficient_limit ||
		c < -coefficient_limit || c > coefficient_limit ||
		component < 0 || component > 3 { return invalid_result }

	discriminant := b * b - 4 * a * c
	denominator := 2.0 * f64(a)
	if discriminant > 0 {
		if component >= 2 { return invalid_result }
		square_root := math.sqrt(f64(discriminant))
		if component == 0 { return (-f64(b) + square_root) / denominator }
		return (-f64(b) - square_root) / denominator
	}
	if discriminant == 0 {
		if component == 0 { return -f64(b) / denominator }
		return invalid_result
	}

	if component < 2 { return -f64(b) / denominator }
	imaginary := math.sqrt(f64(-discriminant)) / denominator
	if component == 2 { return imaginary }
	return -imaginary
}
