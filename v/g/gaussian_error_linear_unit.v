module gaussian_error_linear_unit

import math

const invalid_result = -1.0e300

@[export: 'gaussian_error_linear_unit']
pub fn gaussian_error_linear_unit(x f64) f64 {
	if math.is_nan(x) || x < -100.0 || x > 100.0 { return invalid_result }
	return x * (1.0 / (1.0 + math.exp(-1.702 * x)))
}
