module mean_square_error

const max_length = 256
const invalid_result = -1.0e300

@[export: 'mean_square_error']
pub fn mean_square_error(values &i64, length usize) f64 {
	if unsafe { values == nil } || length < 3 || length > 2 * max_length + 1 { return invalid_result }
	unsafe {
		count_value := values[0]
		if count_value < 1 || count_value > max_length || length != usize(2 * count_value + 1) { return invalid_result }
		count := int(count_value)
		mut error_sum := 0.0
		for index in 0 .. count {
			predicted := values[index + 1]
			expected := values[index + 1 + count]
			if predicted < -1000000 || predicted > 1000000 || expected < -1000000 || expected > 1000000 { return invalid_result }
			difference := f64(expected - predicted)
			error_sum += difference * difference
		}
		return error_sum / f64(count)
	}
}
