module exponential_dist

import math

const max_rate_micro = i64(1_000_000_000)
const invalid_result = -1.0e300

@[export: 'exponential_dist']
pub fn exponential_dist(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 2 { return invalid_result }
	operation, rate_micro := unsafe { values[0] }, unsafe { values[1] }
	if operation < 0 || operation > 2 || rate_micro <= 0 || rate_micro > max_rate_micro { return invalid_result }
	rate := f64(rate_micro) / 1_000_000.0
	if operation == 1 { return 1.0 / math.pow(rate, 2.0) }
	return 1.0 / rate
}
