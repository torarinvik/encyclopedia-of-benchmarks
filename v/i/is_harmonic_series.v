module is_harmonic_series

import math

const invalid_result = -1.0e300
const max_values = 32

@[export: 'is_harmonic_series']
pub fn is_harmonic_series(values &i64, length usize) f64 {
	if values == nil || length < 2 || length > max_values + 1 { return invalid_result }
	count := unsafe { values[0] }
	if count < 1 || count > max_values || length != usize(count + 1) { return invalid_result }
	mut reciprocals := [max_values]f64{}
	unsafe {
		for i in 0 .. int(count) {
			value := math.f64_from_bits(u64(values[i + 1]))
			if value == 0.0 { return invalid_result }
		reciprocals[i] = 1.0 / value
		}
	}
	if count == 1 { return 1.0 }
	common_difference := reciprocals[1] - reciprocals[0]
	for i in 2 .. int(count) {
		if reciprocals[i] - reciprocals[i - 1] != common_difference { return 0.0 }
	}
	return 1.0
}
