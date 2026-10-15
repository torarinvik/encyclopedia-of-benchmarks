module factorial_approximation

import math

@[export: 'factorial_approximation']
pub fn factorial_approximation(x f64) f64 {
	if !(x >= 0.0 && x <= 170.0) { return -1.0 }
	return math.sqrt(3.141592653589793) * math.pow(x / 2.718281828459045, x)
		* math.pow(8.0 * math.pow(x, 3.0) + 4.0 * math.pow(x, 2.0) + x + 1.0 / 30.0, 1.0 / 6.0)
}
