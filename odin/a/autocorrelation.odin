package autocorrelation

import "core:c"

MAX_LENGTH :: 64
INVALID_RESULT :: f64(-1.0e300)

@(export)
autocorrelation :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 4 || length > MAX_LENGTH + 2 do return INVALID_RESULT
	count_value := values[0]
	lag_value := values[1]
	if count_value < 2 || count_value > MAX_LENGTH || length != c.size_t(count_value + 2) || lag_value < 0 || lag_value >= count_value do return INVALID_RESULT
	count := c.size_t(count_value)
	lag := c.size_t(lag_value)
	sum := f64(0)
	for index := c.size_t(0); index < count; index += 1 {
		value := values[index + 2]
		if value < -1000 || value > 1000 do return INVALID_RESULT
		sum += f64(value)
	}
	mean := sum / f64(count)
	variance_sum := f64(0)
	for index := c.size_t(0); index < count; index += 1 {
		difference := f64(values[index + 2]) - mean
		variance_sum += difference * difference
	}
	if variance_sum == 0 do return INVALID_RESULT
	variance := variance_sum / f64(count)
	covariance_sum := f64(0)
	for index := lag; index < count; index += 1 {
		current := f64(values[index + 2]) - mean
		delayed := f64(values[index - lag + 2]) - mean
		covariance_sum += current * delayed
	}
	return (covariance_sum / f64(count)) / variance
}
