module mish

import math

const invalid_result = -1.0e300

// Mish activation for one element of the source vector.
@[export: 'mish']
pub fn mish(x f64) f64 {
	if !(x >= -20.0 && x <= 20.0) { return invalid_result }
	softplus := math.log(1.0 + math.exp(x))
	return x * math.tanh(softplus)
}
