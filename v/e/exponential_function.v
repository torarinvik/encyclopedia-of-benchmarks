module exponential_function

import math

@[export: 'exponential_function']
pub fn exponential_function(power f64, term_count f64) f64 {
	if !(power >= -10.0 && power <= 10.0 && term_count >= 0.0 && term_count <= 32.0) { return -1.0e300 }
	n := int(term_count)
	if f64(n) != term_count { return -1.0e300 }
	if n == 0 { return 1.0 }

	mut output := 0.0
	mut factorial := 1.0
	for i in 0 .. n {
		output += math.pow(power, f64(i)) / factorial
		factorial *= f64(i + 1)
	}
	return output
}
