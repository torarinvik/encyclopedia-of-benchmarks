package spearman_average_rank_correlation

import "core:c"
import "core:math"

INVALID_RESULT :: f64(-1.0e300)

@(export)
spearman_average_rank_correlation :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 5 || length > 257 do return INVALID_RESULT
	count := values[0]
	if count < 2 || count > 128 || length != c.size_t(1 + 2 * count) do return INVALID_RESULT
	n := c.size_t(count)
	for i := c.size_t(0); i < 2 * n; i += 1 {
		value := values[1 + i]
		if value < -1_000_000 || value > 1_000_000 do return INVALID_RESULT
	}
	mean_rank := (f64(n) + 1.0) / 2.0
	covariance := f64(0)
	variance_x := f64(0)
	variance_y := f64(0)
	for i := c.size_t(0); i < n; i += 1 {
		x_value := values[1 + i]
		y_value := values[1 + n + i]
		less_x := i64(0)
		equal_x := i64(0)
		less_y := i64(0)
		equal_y := i64(0)
		for j := c.size_t(0); j < n; j += 1 {
			if values[1 + j] < x_value do less_x += 1
			if values[1 + j] == x_value do equal_x += 1
			if values[1 + n + j] < y_value do less_y += 1
			if values[1 + n + j] == y_value do equal_y += 1
		}
		x_rank := f64(less_x) + (f64(equal_x) + 1.0) / 2.0
		y_rank := f64(less_y) + (f64(equal_y) + 1.0) / 2.0
		dx := x_rank - mean_rank
		dy := y_rank - mean_rank
		covariance += dx * dy
		variance_x += dx * dx
		variance_y += dy * dy
	}
	if variance_x == 0 || variance_y == 0 do return INVALID_RESULT
	return covariance / math.sqrt(variance_x * variance_y)
}
