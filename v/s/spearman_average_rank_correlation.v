module spearman_average_rank_correlation

import math

const invalid_result = -1.0e300

fn average_rank(values &i64, offset usize, count usize, index usize) f64 {
	value := unsafe { values[offset + index] }
	mut less := i64(0)
	mut equal := i64(0)
	for j in 0 .. count {
		other := unsafe { values[offset + j] }
		if other < value { less++ }
		if other == value { equal++ }
	}
	return f64(less) + (f64(equal) + 1.0) / 2.0
}

@[export: 'spearman_average_rank_correlation']
pub fn spearman_average_rank_correlation(values &i64, length usize) f64 {
	if length < 5 { return invalid_result }
	if length > 257 { return invalid_result }
	count := unsafe { values[0] }
	if count < 2 { return invalid_result }
	if count > 128 { return invalid_result }
	if length != usize(1 + 2 * count) { return invalid_result }
	n := usize(count)
	for i in 0 .. 2 * n {
		value := unsafe { values[1 + i] }
		if value < -1000000 { return invalid_result }
		if value > 1000000 { return invalid_result }
	}
	mean_rank := (f64(n) + 1.0) / 2.0
	mut covariance := f64(0)
	mut variance_x := f64(0)
	mut variance_y := f64(0)
	for i in 0 .. n {
		dx := average_rank(values, 1, n, i) - mean_rank
		dy := average_rank(values, 1 + n, n, i) - mean_rank
		covariance += dx * dy
		variance_x += dx * dx
		variance_y += dy * dy
	}
	if variance_x == 0.0 || variance_y == 0.0 { return invalid_result }
	return covariance / math.sqrt(variance_x * variance_y)
}
