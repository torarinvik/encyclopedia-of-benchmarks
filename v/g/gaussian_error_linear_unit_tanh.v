module gaussian_error_linear_unit_tanh

import math

const invalid_result = -1.0e300
const pi_value = 3.14159265358979323846264338327950288
const e_value = 2.71828182845904523536028747135266250

@[export: 'gaussian_error_linear_unit_tanh']
pub fn gaussian_error_linear_unit_tanh(x f64) f64 {
	if math.is_nan(x) || x < -100.0 || x > 100.0 { return invalid_result }
	scale := math.pow(2.0 / pi_value, 0.5)
	z := scale * (x + 0.044715 * math.pow(x, 3.0))
	tanh_value := 2.0 / (1.0 + math.pow(e_value, -2.0 * z)) - 1.0
	return x * 0.5 * (1.0 + tanh_value)
}
