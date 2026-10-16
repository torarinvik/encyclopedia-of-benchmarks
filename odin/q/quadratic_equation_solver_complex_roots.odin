package quadratic_equation_solver_complex_roots

import "core:c"
import "core:math"

COEFFICIENT_LIMIT :: i64(1_000_000)
INVALID_RESULT :: f64(-1.0e300)

@(export)
quadratic_equation_solver_complex_roots :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 4 do return INVALID_RESULT
	a, b, c_value, component := values[0], values[1], values[2], values[3]
	if a == 0 || a < -COEFFICIENT_LIMIT || a > COEFFICIENT_LIMIT ||
		b < -COEFFICIENT_LIMIT || b > COEFFICIENT_LIMIT ||
		c_value < -COEFFICIENT_LIMIT || c_value > COEFFICIENT_LIMIT ||
		component < 0 || component > 3 do return INVALID_RESULT

	discriminant := b * b - 4 * a * c_value
	denominator := 2.0 * f64(a)
	if discriminant > 0 {
		if component >= 2 do return INVALID_RESULT
		square_root := math.sqrt(f64(discriminant))
		if component == 0 do return (-f64(b) + square_root) / denominator
		return (-f64(b) - square_root) / denominator
	}
	if discriminant == 0 {
		if component == 0 do return -f64(b) / denominator
		return INVALID_RESULT
	}

	if component < 2 do return -f64(b) / denominator
	imaginary := math.sqrt(f64(-discriminant)) / denominator
	if component == 2 do return imaginary
	return -imaginary
}
