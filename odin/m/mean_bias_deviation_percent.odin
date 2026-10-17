package mean_bias_deviation_percent

import "core:c"

INVALID_RESULT :: -1.0e300

mean_bias_deviation_percent :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length < 1 || length > 131 do return INVALID_RESULT
	if input[0] < 1 || input[0] > 64 do return INVALID_RESULT
	count := c.size_t(input[0])
	if length != 1 + 2 * count do return INVALID_RESULT
	difference_sum: i64 = 0
	actual_sum: i64 = 0
	for index := c.size_t(0); index < count; index += 1 {
		prediction := input[1 + index]
		actual := input[1 + count + index]
		if prediction < -1000 || prediction > 1000 || actual < -1000 || actual > 1000 do return INVALID_RESULT
		difference_sum += prediction - actual
		actual_sum += actual
	}
	if actual_sum == 0 do return INVALID_RESULT
	numerator := f64(difference_sum) / f64(count)
	denominator := f64(actual_sum) / f64(count)
	return numerator / denominator * 100.0
}
