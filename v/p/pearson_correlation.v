module pearson_correlation

import math

const invalid_result = -1.0e300

@[export: 'pearson_correlation']
pub fn pearson_correlation(values &i64, length usize) f64 {
	if length < 5 { return invalid_result }
	if length > 257 { return invalid_result }
	count := unsafe { values[0] }
	if count < 2 { return invalid_result }
	if count > 128 { return invalid_result }
	if length != usize(1 + 2 * count) { return invalid_result }
	mut sum_x := f64(0)
	mut sum_y := f64(0)
	for i in 0 .. usize(count) {
		x := unsafe { values[1 + i] }
		y := unsafe { values[1 + usize(count) + i] }
		if x < -1000000 { return invalid_result }
		if x > 1000000 { return invalid_result }
		if y < -1000000 { return invalid_result }
		if y > 1000000 { return invalid_result }
		sum_x += f64(x)
		sum_y += f64(y)
	}
	mean_x := sum_x / f64(count)
	mean_y := sum_y / f64(count)
	mut covariance := f64(0)
	mut variance_x := f64(0)
	mut variance_y := f64(0)
	for i in 0 .. usize(count) {
		dx := f64(unsafe { values[1 + i] }) - mean_x
		dy := f64(unsafe { values[1 + usize(count) + i] }) - mean_y
		covariance += dx * dy
		variance_x += dx * dx
		variance_y += dy * dy
	}
	if variance_x == 0.0 { return invalid_result }
	if variance_y == 0.0 { return invalid_result }
	return covariance / math.sqrt(variance_x * variance_y)
}
