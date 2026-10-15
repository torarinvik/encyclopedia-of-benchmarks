module standard_deviation

import math

const max_length = 64
const max_abs_value = i64(1_000_000)
const invalid_result = -1.0e300

@[export: 'standard_deviation']
pub fn standard_deviation(values &i64, length usize) f64 {
	if length == 0 || length > max_length { return invalid_result }
	mut sum := 0.0
	for index in 0 .. length {
		value := unsafe { values[index] }
		if value < -max_abs_value || value > max_abs_value { return invalid_result }
		sum += f64(value)
	}
	average := sum / f64(length)
	mut squared_deviations := 0.0
	for index in 0 .. length {
		difference := f64(unsafe { values[index] }) - average
		squared_deviations += math.pow(difference, 2.0)
	}
	return math.sqrt(squared_deviations / f64(length))
}
