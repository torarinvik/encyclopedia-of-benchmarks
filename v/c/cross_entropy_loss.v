module cross_entropy_loss

import math

const max_count = 64
const scale = 1_000_000.0

@[export: 'cross_entropy_loss']
pub fn cross_entropy_loss(values &i64, length usize) f64 {
	if length < 1 { return -1.0e300 }
	count := unsafe { values[0] }
	if count < 1 || count > max_count || length != 1 + 2 * usize(count) { return -1.0e300 }
	mut terms := [max_count]f64{}
	for i in 0 .. int(count) {
		actual_scaled := unsafe { values[1 + i] }
		predicted_scaled := unsafe { values[1 + int(count) + i] }
		if actual_scaled < 0 || actual_scaled > 1_000_000 || predicted_scaled < 1 || predicted_scaled > 1_000_000 { return -1.0e300 }
		actual := f64(actual_scaled) / scale
		predicted := f64(predicted_scaled) / scale
		terms[i] = -actual * math.log(predicted)
	}
	mut total := 0.0
	for i in 0 .. int(count) { total += terms[i] }
	return total
}
