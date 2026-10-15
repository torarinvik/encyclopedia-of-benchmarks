module mean_absolute_error_loss

const max_length = 256
const invalid_result = -1.0e300

@[export: 'mean_absolute_error_loss']
pub fn mean_absolute_error_loss(values &i64, length usize) f64 {
	if unsafe { values == nil } || length < 3 || length > 2 * max_length + 1 { return invalid_result }
	unsafe {
		count_value := values[0]
		if count_value < 1 || count_value > max_length || length != usize(2 * count_value + 1) { return invalid_result }
		count := int(count_value)
		mut absolute_sum := 0.0
		for index in 0 .. count {
			predicted := values[index + 1]
			actual := values[index + 1 + count]
			if predicted < -1000000 || predicted > 1000000 || actual < -1000000 || actual > 1000000 { return invalid_result }
			difference := f64(predicted - actual)
			absolute_sum += if difference < 0 { -difference } else { difference }
		}
		return absolute_sum / f64(count)
	}
}
