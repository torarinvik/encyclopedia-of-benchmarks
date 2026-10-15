module softplus

import math

const invalid_result = -1.0e300

@[export: 'softplus']
pub fn softplus(x f64) f64 {
	if math.is_nan(x) || x < -100.0 || x > 100.0 { return invalid_result }
	return math.log(1.0 + math.exp(x))
}
