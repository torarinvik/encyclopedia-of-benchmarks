module swish

import math

const invalid_result = -1.0e300

@[export: 'swish']
pub fn swish(x f64) f64 {
	if math.is_nan(x) || x < -100.0 || x > 100.0 { return invalid_result }
	scaled := 1.0 * x
	return x * (1.0 / (1.0 + math.exp(-scaled)))
}
