module autocorrelation

const max_length = 64
const invalid_result = -1.0e300

@[export: 'autocorrelation']
pub fn autocorrelation(values &i64, length usize) f64 {
	if unsafe { values == nil } || length < 4 || length > max_length + 2 { return invalid_result }
	unsafe {
		count_value := values[0]
		lag_value := values[1]
		if count_value < 2 || count_value > max_length || length != usize(count_value + 2) || lag_value < 0 || lag_value >= count_value { return invalid_result }
		count := int(count_value)
		lag := int(lag_value)
		mut sum := 0.0
		for index in 0 .. count {
			value := values[index + 2]
			if value < -1000 || value > 1000 { return invalid_result }
			sum += f64(value)
		}
		mean := sum / f64(count)
		mut variance_sum := 0.0
		for index in 0 .. count {
			difference := f64(values[index + 2]) - mean
			variance_sum += difference * difference
		}
		if variance_sum == 0 { return invalid_result }
		variance := variance_sum / f64(count)
		mut covariance_sum := 0.0
		for index in lag .. count {
			current := f64(values[index + 2]) - mean
			delayed := f64(values[index - lag + 2]) - mean
			covariance_sum += current * delayed
		}
		return (covariance_sum / f64(count)) / variance
	}
}
