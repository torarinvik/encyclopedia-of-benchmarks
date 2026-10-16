package kendall_rank_correlation_coefficient

import "core:c"
import "core:math"

INVALID_RESULT :: f64(-1.0e300)

@(export)
kendall_rank_correlation_coefficient :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 5 || length > 257 do return INVALID_RESULT
	count := values[0]
	if count < 2 || count > 128 || length != c.size_t(1 + 2 * count) do return INVALID_RESULT
	for i := c.size_t(0); i < c.size_t(2 * count); i += 1 {
		value := values[1 + i]
		if value < -1_000_000 || value > 1_000_000 do return INVALID_RESULT
	}

	concordant := i64(0)
	discordant := i64(0)
	ties_x := i64(0)
	ties_y := i64(0)
	n := c.size_t(count)
	for i := c.size_t(0); i < n; i += 1 {
		for j := i + 1; j < n; j += 1 {
			x1 := values[1 + i]
			x2 := values[1 + j]
			y1 := values[1 + n + i]
			y2 := values[1 + n + j]
			if x1 == x2 do ties_x += 1
			if y1 == y2 do ties_y += 1
			if (x1 < x2 && y1 < y2) || (x1 > x2 && y1 > y2) do concordant += 1
			else if (x1 < x2 && y1 > y2) || (x1 > x2 && y1 < y2) do discordant += 1
		}
	}
	pairs := f64(n * (n - 1) / 2)
	denominator := math.sqrt((pairs - f64(ties_x)) * (pairs - f64(ties_y)))
	if denominator == 0 do return INVALID_RESULT
	return f64(concordant - discordant) / denominator
}
