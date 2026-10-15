package manhattan_distance

import "core:c"

@(export)
manhattan_distance :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 3 do return -1.0e300
	dimensions := values[0]
	if dimensions < 1 || dimensions > 16 || length != 1 + 2 * c.size_t(dimensions) do return -1.0e300
	total := i64(0)
	for index := c.size_t(0); index < c.size_t(dimensions); index += 1 {
		first := values[1 + index]
		second := values[1 + c.size_t(dimensions) + index]
		if first < -1_000_000 || first > 1_000_000 || second < -1_000_000 || second > 1_000_000 do return -1.0e300
		difference := first - second
		if difference < 0 {
			total -= difference
		} else {
			total += difference
		}
	}
	return f64(total)
}
