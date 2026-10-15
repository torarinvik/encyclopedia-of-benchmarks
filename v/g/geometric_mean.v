module geometric_mean

import math

const max_length = 6
const max_abs_value = i64(100)
const invalid_result = -1.0e300

@[export: 'geometric_mean']
pub fn geometric_mean(values &i64, length usize) f64 {
	if length == 0 || length > max_length { return invalid_result }
	mut product := i64(1)
	for index in 0 .. length {
		value := unsafe { values[index] }
		if value < -max_abs_value || value > max_abs_value { return invalid_result }
		product *= value
	}
	if product < 0 && length % 2 == 0 { return invalid_result }
	magnitude := if product < 0 { -product } else { product }
	mut root := math.pow(f64(magnitude), 1.0 / f64(length))
	rounded := math.floor(root + 0.5)
	mut rounded_power := i64(1)
	for _ in 0 .. length { rounded_power *= i64(rounded) }
    if (product >= 0 && rounded_power == product) || (product < 0 && length % 2 == 1 && -rounded_power == product) { root = rounded }
	if product < 0 { root = -root }
	return root
}
