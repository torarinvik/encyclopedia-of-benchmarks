module mean_bias_deviation_percent

const invalid_result = -1.0e300

@[export: 'mean_bias_deviation_percent']
pub fn mean_bias_deviation_percent(input &i64, length usize) f64 {
	if input == nil || length < 1 || length > 131 { return invalid_result }
	unsafe {
		if input[0] < 1 || input[0] > 64 { return invalid_result }
		count := int(input[0])
		if int(length) != 1 + 2 * count { return invalid_result }
		mut difference_sum := i64(0)
		mut actual_sum := i64(0)
		for index := 0; index < count; index++ {
			prediction := input[1 + index]
			actual := input[1 + count + index]
			if prediction < -1000 || prediction > 1000 || actual < -1000 || actual > 1000 { return invalid_result }
			difference_sum += prediction - actual
			actual_sum += actual
		}
		if actual_sum == 0 { return invalid_result }
		numerator := f64(difference_sum) / f64(count)
		denominator := f64(actual_sum) / f64(count)
		return numerator / denominator * 100.0
	}
}
