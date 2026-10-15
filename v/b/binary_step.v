module binary_step

import math

const invalid_result = -1.0e300

@[export: 'binary_step']
pub fn binary_step(x f64) f64 {
	if math.is_nan(x) || x < -1_000_000.0 || x > 1_000_000.0 { return invalid_result }
	if x >= 0.0 { return 1.0 }
	return 0.0
}
