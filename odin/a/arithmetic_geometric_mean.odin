package arithmetic_geometric_mean

import "core:math"

MAX_VALUE :: 1_000_000.0
INVALID_RESULT :: f64 = -1.0

@(export)
arithmetic_geometric_mean :: proc "c" (first, second: f64) -> f64 {
	if first != first || second != second || first < 0.0 || second < 0.0 ||
		first > MAX_VALUE || second > MAX_VALUE do return INVALID_RESULT
	if first == second do return first

	arithmetic := first
	geometric := second
	for {
		previous := arithmetic
		next_arithmetic := (arithmetic + geometric) / 2.0
		next_geometric := math.sqrt(arithmetic * geometric)
		arithmetic = next_arithmetic
		geometric = next_geometric
		if arithmetic == previous do break
	}
	return arithmetic
}
