package montecarlopi

import "core:c"
import "core:math"

MAX_PARSEABLE_INPUT_LENGTH :: 130

exact_integer :: proc(value: f64, minimum, maximum: i64) -> bool {
	if math.is_nan(value) || math.is_inf(value) || value < f64(minimum) || value > f64(maximum) do return false
	return f64(i64(value)) == value
}

allowed_coordinate :: proc(value: f64) -> bool {
	return value == 0 || value == 0.25 || value == 0.5 || value == 0.75
}

@(export)
montecarlopi :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 3 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	if !exact_integer(input[0], 1, 64) do return -1
	point_count := int(input[0])
	if input_length != c.size_t(1 + 2 * point_count) do return -1
	inside := 0
	for point := 0; point < point_count; point += 1 {
		x, y := input[1 + 2*point], input[2 + 2*point]
		if !allowed_coordinate(x) || !allowed_coordinate(y) do return -1
		if x*x + y*y <= 1.0 do inside += 1
	}
	estimate := f64(inside) / f64(point_count) * 4.0
	if math.is_nan(estimate) || math.is_inf(estimate) do return -1
	if output == nil || capacity < 1 do return -2
	output[0] = estimate
	return 1
}
