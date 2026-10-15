module leaky_relu

import math

const invalid_result = -1.0e300
const max_input = 1_000_000.0

@[export: 'leaky_relu']
pub fn leaky_relu(x f64, alpha f64) f64 {
	if math.is_nan(x) || math.is_nan(alpha) || x < -max_input || x > max_input || alpha < -max_input || alpha > max_input { return invalid_result }
	if x < 0.0 { return x * alpha }
	return x
}
