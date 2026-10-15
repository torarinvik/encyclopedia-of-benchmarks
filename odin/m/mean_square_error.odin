package mean_square_error

import "core:c"

MAX_LENGTH :: 256
INVALID_RESULT :: f64(-1.0e300)

@(export)
mean_square_error :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 3 || length > 2 * MAX_LENGTH + 1 do return INVALID_RESULT
	count_value := values[0]
	if count_value < 1 || count_value > MAX_LENGTH || length != c.size_t(2 * count_value + 1) do return INVALID_RESULT
	count := c.size_t(count_value)
	error_sum := f64(0)
	for index := c.size_t(0); index < count; index += 1 {
		predicted := values[index + 1]
		expected := values[index + 1 + count]
		if predicted < -1000000 || predicted > 1000000 || expected < -1000000 || expected > 1000000 do return INVALID_RESULT
		difference := f64(expected - predicted)
		error_sum += difference * difference
	}
	return error_sum / f64(count)
}
