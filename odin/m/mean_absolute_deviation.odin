package mean_absolute_deviation

import "core:c"

MAX_LENGTH :: 256
INVALID_RESULT :: f64(-1.0e300)

@(export)
mean_absolute_deviation :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 2 || length > MAX_LENGTH + 1 do return INVALID_RESULT
	count_value := values[0]
	if count_value < 1 || count_value > MAX_LENGTH || length != c.size_t(count_value + 1) do return INVALID_RESULT
	count := c.size_t(count_value)
	sum := f64(0)
	for index := c.size_t(0); index < count; index += 1 {
		value := values[index + 1]
		if value < -1000000 || value > 1000000 do return INVALID_RESULT
		sum += f64(value)
	}
	mean := sum / f64(count)
	absolute_sum := f64(0)
	for index := c.size_t(0); index < count; index += 1 {
		difference := f64(values[index + 1]) - mean
		if difference < 0 do difference = -difference
		absolute_sum += difference
	}
	return absolute_sum / f64(count)
}
