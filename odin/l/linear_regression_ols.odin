package linear_regression_ols

import "core:c"

MAX_OBSERVATIONS :: 128
INVALID_RESULT :: f64(-1.0e300)

@(export)
linear_regression_ols :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 5 || length > 257 || length % 2 == 0 do return INVALID_RESULT
	count := values[0]
	if count < 2 || count > MAX_OBSERVATIONS || length != c.size_t(1 + 2 * count) do return INVALID_RESULT

	sum_x := f64(0)
	sum_y := f64(0)
	for index := c.size_t(0); index < c.size_t(count); index += 1 {
		x := values[1 + 2 * index]
		y := values[2 + 2 * index]
		if x < -1_000_000 || x > 1_000_000 || y < -1_000_000 || y > 1_000_000 do return INVALID_RESULT
		sum_x += f64(x)
		sum_y += f64(y)
	}
	mean_x := sum_x / f64(count)
	mean_y := sum_y / f64(count)
	covariance := f64(0)
	variance_x := f64(0)
	variance_y := f64(0)
	for index := c.size_t(0); index < c.size_t(count); index += 1 {
		dx := f64(values[1 + 2 * index]) - mean_x
		dy := f64(values[2 + 2 * index]) - mean_y
		covariance += dx * dy
		variance_x += dx * dx
		variance_y += dy * dy
	}
	if variance_x <= 1e-12 || variance_y <= 1e-12 do return INVALID_RESULT
	return covariance / variance_x
}
