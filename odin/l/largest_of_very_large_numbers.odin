package largest_of_very_large_numbers

import "core:math"

MAX_VALUE :: i64(1000000000000)

source_score :: proc "contextless" (base, exponent: i64) -> f64 {
	if base == 0 do return 0.0
	if exponent == 0 do return 1.0
	return f64(exponent) * math.log10(f64(base))
}

valid_comparison_domain :: proc "contextless" (base_a, exponent_a, base_b, exponent_b: i64) -> bool {
	return exponent_a == exponent_b ||
		(base_a == base_b && (base_a == 0 || ((exponent_a == 0) == (exponent_b == 0))))
}

@(export)
largest_of_very_large_numbers :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 4 do return -2
	for i := 0; i < 4; i += 1 { if values[i] < 0 || values[i] > MAX_VALUE do return -2 }
	if !valid_comparison_domain(values[0], values[1], values[2], values[3]) do return -2
	a := source_score(values[0], values[1])
	b := source_score(values[2], values[3])
	if a > b do return 1
	if a < b do return -1
	return 0
}
