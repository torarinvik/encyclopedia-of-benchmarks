module weighted_average

const max_n = i64(64)
const max_abs_value = i64(1_000_000)
const invalid_result = -1.0e300

@[export: 'weighted_average']
pub fn weighted_average(packed &i64, length usize) f64 {
	if length < 1 || length > 129 { return invalid_result }
	n := unsafe { packed[0] }
	if n < 1 || n > max_n || length != usize(1 + 2 * n) { return invalid_result }
	mut weighted_sum := i64(0)
	mut total_weight := i64(0)
	for index in 0 .. int(n) {
		value := unsafe { packed[1 + index] }
		weight := unsafe { packed[1 + int(n) + index] }
		if value < -max_abs_value || value > max_abs_value || weight < -max_abs_value || weight > max_abs_value { return invalid_result }
		weighted_sum += value * weight
		total_weight += weight
	}
	if total_weight == 0 { return invalid_result }
	return f64(weighted_sum) / f64(total_weight)
}
