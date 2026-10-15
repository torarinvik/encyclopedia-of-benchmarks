package factorial_approximation

import "core:math"

@(export)
factorial_approximation :: proc "c" (x: f64) -> f64 {
	if !(x >= 0.0 && x <= 170.0) do return -1.0
	return math.sqrt_f64(3.141592653589793) * math.pow_f64(x / 2.718281828459045, x)
		* math.pow_f64(8.0 * math.pow_f64(x, 3.0) + 4.0 * math.pow_f64(x, 2.0) + x + 1.0 / 30.0, 1.0 / 6.0)
}
