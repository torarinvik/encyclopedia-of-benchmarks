module hickerson_almost_integer

import math

const invalid_result = -1.0e300

@[export: 'hickerson_almost_integer']
pub fn hickerson_almost_integer(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 1 { return invalid_result }
	unsafe {
		n := values[0]
		if n < 1 || n > 17 { return invalid_result }
		log_two := math.log(2.0)
		mut value := 1.0 / (2.0 * log_two * log_two)
		for index in 2 .. n + 1 { value = (f64(index) / log_two) * value }
		return value
	}
}
