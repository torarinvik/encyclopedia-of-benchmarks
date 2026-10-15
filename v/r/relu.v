module relu

import math

const invalid_result = -1.0e300
const max_input = 16777216.0

@[export: 'relu']
pub fn relu(x f64) f64 {
	if math.is_nan(x) || x < -max_input || x > max_input || f64(i64(x)) != x { return invalid_result }
	if x > 0.0 { return x }
	return 0.0
}
