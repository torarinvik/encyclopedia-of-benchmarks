module main

import math

const invalid_result = -1.0e300

fn objective(x f64) f64 { return x * x - 3.0 }

@[export: 'secant']
pub fn secant(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 5 {
		return invalid_result
	}
	if unsafe { values[0] != 0 || values[1] < 1000000 || values[1] > 1500000 ||
		values[2] < 1600000 || values[2] > 2000000 || values[1] >= values[2] ||
		values[3] < 1 || values[3] > 100000 || values[4] < 0 || values[4] > 32 } {
		return invalid_result
	}
	mut x0 := f64(unsafe { values[1] }) / 1000000.0
	mut x1 := f64(unsafe { values[2] }) / 1000000.0
	tolerance := f64(unsafe { values[3] }) / 1000000000.0
	max_updates := unsafe { values[4] }
	for update in i64(0) .. max_updates + 1 {
		f1 := objective(x1)
		if math.abs(f1) <= tolerance {
			return x1
		}
		if update == max_updates {
			break
		}
		f0 := objective(x0)
		denominator := f1 - f0
		if denominator == 0.0 {
			return invalid_result
		}
		x2 := x1 - f1 * (x1 - x0) / denominator
		if math.is_nan(x2) || math.is_inf(x2) {
			return invalid_result
		}
		x0 = x1
		x1 = x2
	}
	return invalid_result
}
