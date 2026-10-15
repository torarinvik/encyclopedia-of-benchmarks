module tanh

import math

const invalid_result = -1.0e300

@[export: 'tanh']
pub fn tanh(x f64) f64 {
	if math.is_nan(x) || x < -10.0 || x > 10.0 { return invalid_result }
	return (2.0 / (1.0 + math.exp(-2.0 * x))) - 1.0
}
