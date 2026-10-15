package euclidean_distance

import "core:c"
import "core:math"

MAX_DIMENSION :: 128

@(export)
euclidean_distance :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 1 do return -1.0e300
	dimension := values[0]
	if dimension < 0 || dimension > MAX_DIMENSION do return -1.0e300
	if length != c.size_t(1 + 2 * dimension) do return -1.0e300
	sum_of_squares := 0.0
	for i := 0; i < int(dimension); i += 1 {
		first := values[1 + i]
		second := values[1 + int(dimension) + i]
		if first < -1_000_000 || first > 1_000_000 || second < -1_000_000 || second > 1_000_000 do return -1.0e300
		difference := f64(first) - f64(second)
		sum_of_squares += difference * difference
	}
	return math.sqrt(sum_of_squares)
}
