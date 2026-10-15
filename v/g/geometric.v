module geometric

import math

const invalid_result = -1.0e300

// Operation 0 tests a geometric sequence; operation 1 computes its mean.
@[export: 'geometric']
pub fn geometric(values &i64, length usize) f64 {
	if length < 2 { return invalid_result }
	operation := unsafe { values[0] }
	count := length - 1
	if operation == 0 {
		if count > 16 { return invalid_result }
		for index in usize(1) .. length {
			value := unsafe { values[index] }
			if value < -100 || value > 100 { return invalid_result }
		}
		if count == 1 { return 1.0 }
		first := unsafe { values[1] }
		if first == 0 { return 0.0 }
		common_ratio := f64(unsafe { values[2] }) / f64(first)
		for index in usize(0) .. count - 1 {
			current := unsafe { values[index + 1] }
			if current == 0 { return 0.0 }
			next := unsafe { values[index + 2] }
			if f64(next) / f64(current) != common_ratio { return 0.0 }
		}
		return 1.0
	}
	if operation == 1 {
		if count > 7 { return invalid_result }
		mut product := i64(1)
		for index in usize(1) .. length {
			value := unsafe { values[index] }
			if value < 0 || value > 100 { return invalid_result }
			product *= value
		}
		return math.pow(f64(product), 1.0 / f64(count))
	}
	invalid_result
}
