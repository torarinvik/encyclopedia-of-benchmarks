module softsign

import math

const invalid_result = -1.0e300

@[export: 'softsign']
pub fn softsign(x f64) f64 {
	if math.is_nan(x) || x < -1.0e100 || x > 1.0e100 { return invalid_result }
	return x / (1.0 + math.abs(x))
}
