module kendall_rank_correlation_coefficient

import math

const invalid_result = -1.0e300

@[export: 'kendall_rank_correlation_coefficient']
pub fn kendall_rank_correlation_coefficient(values &i64, length usize) f64 {
	if length < 5 { return invalid_result }
	if length > 257 { return invalid_result }
	count := unsafe { values[0] }
	if count < 2 { return invalid_result }
	if count > 128 { return invalid_result }
	if length != usize(1 + 2 * count) { return invalid_result }
	for i in 0 .. usize(2 * count) {
		value := unsafe { values[1 + i] }
		if value < -1000000 { return invalid_result }
		if value > 1000000 { return invalid_result }
	}
	mut concordant := i64(0)
	mut discordant := i64(0)
	mut ties_x := i64(0)
	mut ties_y := i64(0)
	n := usize(count)
	for i in 0 .. n {
		for j in i + 1 .. n {
			x1 := unsafe { values[1 + i] }
			x2 := unsafe { values[1 + j] }
			y1 := unsafe { values[1 + n + i] }
			y2 := unsafe { values[1 + n + j] }
			if x1 == x2 { ties_x++ }
			if y1 == y2 { ties_y++ }
			if (x1 < x2 && y1 < y2) || (x1 > x2 && y1 > y2) { concordant++ }
			else if (x1 < x2 && y1 > y2) || (x1 > x2 && y1 < y2) { discordant++ }
		}
	}
	pairs := f64(n * (n - 1) / 2)
	denominator := math.sqrt((pairs - f64(ties_x)) * (pairs - f64(ties_y)))
	if denominator == 0.0 { return invalid_result }
	return f64(concordant - discordant) / denominator
}
