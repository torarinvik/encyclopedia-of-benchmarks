package pearson_correlation

import "core:c"
import "core:math"

MAX_OBSERVATIONS :: 128
MAX_ABS_VALUE :: i64(1_000_000)
INVALID_RESULT :: f64(-1.0e300)

@(export)
pearson_correlation :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 5 || length > 257 do return INVALID_RESULT
	count := values[0]
	if count < 2 || count > MAX_OBSERVATIONS || length != c.size_t(1 + 2 * count) do return INVALID_RESULT

	sum_x := f64(0)
	sum_y := f64(0)
	for i := c.size_t(0); i < c.size_t(count); i += 1 {
		x := values[1 + i]
		y := values[1 + c.size_t(count) + i]
		if x < -MAX_ABS_VALUE || x > MAX_ABS_VALUE || y < -MAX_ABS_VALUE || y > MAX_ABS_VALUE do return INVALID_RESULT
		sum_x += f64(x)
		sum_y += f64(y)
	}
	mean_x := sum_x / f64(count)
	mean_y := sum_y / f64(count)
	covariance := f64(0)
	variance_x := f64(0)
	variance_y := f64(0)
	for i := c.size_t(0); i < c.size_t(count); i += 1 {
		dx := f64(values[1 + i]) - mean_x
		dy := f64(values[1 + c.size_t(count) + i]) - mean_y
		covariance += dx * dy
		variance_x += dx * dx
		variance_y += dy * dy
	}
	if variance_x == 0 || variance_y == 0 do return INVALID_RESULT
	return covariance / math.sqrt(variance_x * variance_y)
}
