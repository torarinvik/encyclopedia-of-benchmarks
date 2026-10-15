module squareplus

import math

const invalid_result = -1.0e300

// Squareplus activation for one element of the source vector.
@[export: 'squareplus']
pub fn squareplus(x f64, beta f64) f64 {
	if !(x >= -10000.0 && x <= 10000.0 && beta >= 0.25 && beta <= 10000.0) { return invalid_result }
	return (x + math.sqrt(x * x + beta)) / 2.0
}
