module mean_absolute_deviation

const max_length = 256
const invalid_result = -1.0e300

@[export: 'mean_absolute_deviation']
pub fn mean_absolute_deviation(values &i64, length usize) f64 {
	if unsafe { values == nil } || length < 2 || length > max_length + 1 { return invalid_result }
	unsafe {
		count_value := values[0]
		if count_value < 1 || count_value > max_length || length != usize(count_value + 1) { return invalid_result }
		count := int(count_value)
		mut sum := 0.0
		for index in 0 .. count {
			value := values[index + 1]
			if value < -1000000 || value > 1000000 { return invalid_result }
			sum += f64(value)
		}
		mean := sum / f64(count)
		mut absolute_sum := 0.0
		for index in 0 .. count {
			difference := f64(values[index + 1]) - mean
			absolute_sum += if difference < 0 { -difference } else { difference }
		}
		return absolute_sum / f64(count)
	}
}
