module sigmoid

import math

const invalid_result = -1.0e300

@[export: 'sigmoid']
pub fn sigmoid(x f64) f64 {
	if math.is_nan(x) || x < -20.0 || x > 20.0 { return invalid_result }
	return 1.0 / (1.0 + math.exp(-x))
}
