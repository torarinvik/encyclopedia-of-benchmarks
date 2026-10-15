module average

const max_input_length = 4096
const max_abs_value = i64(1_000_000_000)
const invalid_result = -1.0e300

@[export: 'average']
pub fn average(values &i64, length usize) f64 {
	if length == 0 || length > max_input_length { return invalid_result }
	mut sum := i64(0)
	for index in 0 .. length {
		value := unsafe { values[index] }
		if value < -max_abs_value || value > max_abs_value { return invalid_result }
		sum += value
	}
	return f64(sum) / f64(length)
}
