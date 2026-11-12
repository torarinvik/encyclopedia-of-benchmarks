package box_muller_cartesian_normal

import "core:c"
import "core:math"

MAX_PAIRS :: 64
DRAW_SCALE :: 4294967296.0
TAU :: 6.283185307179586476925286766559

is_bounded_integer :: proc "contextless" (value, minimum, maximum: f64) -> bool {
	return math.is_finite(value) && math.trunc(value) == value && value >= minimum && value <= maximum
}

@(export)
box_muller_cartesian_normal :: proc "c" (input: [^]f64, length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 1 + 2 * MAX_PAIRS do return -1
	if !is_bounded_integer(input[0], 1.0, f64(MAX_PAIRS)) do return -1
	pair_count := int(input[0])
	if length != c.size_t(1 + 2 * pair_count) do return -1
	for index := 0; index < 2 * pair_count; index += 1 {
		if !is_bounded_integer(input[1 + index], 0.0, 4294967295.0) do return -1
	}

	result_count := 2 * pair_count
	if output == nil || capacity < c.size_t(result_count) do return -2
	for pair := 0; pair < pair_count; pair += 1 {
		radial := (input[1 + 2 * pair] + 1.0) / DRAW_SCALE
		angular := input[2 + 2 * pair] / DRAW_SCALE
		radius := math.sqrt_f64(-2.0 * math.ln_f64(radial))
		angle := TAU * angular
		output[2 * pair] = radius * math.cos_f64(angle)
		output[2 * pair + 1] = radius * math.sin_f64(angle)
	}
	return i64(result_count)
}
