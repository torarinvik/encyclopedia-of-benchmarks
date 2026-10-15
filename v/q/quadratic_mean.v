module quadratic_mean

import math

const max_length = 64
const invalid_result = -1.0e300

@[export: 'quadratic_mean']
pub fn quadratic_mean(values &i64, length usize) f64 {
	if unsafe { values == nil } || length == 0 || length > max_length { return invalid_result }
	unsafe {
		mut square_sum := 0.0
		for index in 0 .. int(length) {
			value := values[index]
			if value < -1000 || value > 1000 { return invalid_result }
			converted := f64(value)
			square_sum += converted * converted
		}
		return math.sqrt(square_sum / f64(length))
	}
}
