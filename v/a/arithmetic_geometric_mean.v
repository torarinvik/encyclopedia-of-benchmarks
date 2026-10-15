module arithmetic_geometric_mean

import math

const max_value = 1_000_000.0
const invalid_result = -1.0

@[export: 'arithmetic_geometric_mean']
pub fn arithmetic_geometric_mean(first f64, second f64) f64 {
	if first != first || second != second || first < 0.0 || second < 0.0 ||
		first > max_value || second > max_value { return invalid_result }
	if first == second { return first }

	mut arithmetic := first
	mut geometric := second
	for {
		previous := arithmetic
		next_arithmetic := (arithmetic + geometric) / 2.0
		next_geometric := math.sqrt(arithmetic * geometric)
		arithmetic = next_arithmetic
		geometric = next_geometric
		if arithmetic == previous { break }
	}
	return arithmetic
}
