module missing_number

const max_values = 1024

// Return the absent value from 0 through the number of supplied values.
@[export: 'missing_number']
pub fn missing_number(values &i64, length usize) i64 {
	if length > max_values { return -1 }
	mut seen := [max_values + 1]bool{}
	mut actual_sum := i64(0)
	for index in 0 .. int(length) {
		value := unsafe { values[index] }
		if value < 0 || value > i64(length) { return -1 }
		if seen[int(value)] { return -1 }
		seen[int(value)] = true
		actual_sum += value
	}
	n := i64(length)
	return n * (n + 1) / 2 - actual_sum
}
