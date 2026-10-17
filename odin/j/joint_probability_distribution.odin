package joint_probability_distribution

import "core:c"

MAX_SUPPORT_LENGTH :: 4
MAX_PARSEABLE_INPUT_LENGTH :: 20
MAX_OUTPUT_ELEMENTS :: 48

parse_count :: proc(raw: f64, count: ^c.size_t) -> bool {
	if raw != raw || raw < 1.0 || raw > f64(MAX_SUPPORT_LENGTH) do return false
	parsed := c.size_t(raw)
	if f64(parsed) != raw do return false
	count^ = parsed
	return true
}

parse_support :: proc(raw: f64, support: ^i64) -> bool {
	if raw != raw || raw < -1000.0 || raw > 1000.0 do return false
	parsed := i64(raw)
	if f64(parsed) != raw do return false
	support^ = parsed
	return true
}

valid_probability :: proc(value: f64) -> bool {
	return value == value && value >= -1_000_000.0 && value <= 1_000_000.0
}

@(export)
joint_probability_distribution :: proc "c" (input: [^]f64, input_len: c.size_t,
		output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_len < 2 || input_len > MAX_PARSEABLE_INPUT_LENGTH do return -1
	var x_count, y_count: c.size_t
	if !parse_count(input[0], &x_count) || !parse_count(input[1], &y_count) do return -1
	if input_len != 2 + 2*x_count + 2*y_count do return -1

	x_start := c.size_t(2)
	y_start := x_start + x_count
	x_probability_start := y_start + y_count
	y_probability_start := x_probability_start + x_count
	var x_values: [4]i64
	var y_values: [4]i64
	var x_probabilities: [4]f64
	var y_probabilities: [4]f64

	for index in 0..<x_count {
		if !parse_support(input[x_start + index], &x_values[index]) ||
			!valid_probability(input[x_probability_start + index]) do return -1
		x_probabilities[index] = input[x_probability_start + index]
		for previous in 0..<index {
			if x_values[previous] == x_values[index] do return -1
		}
	}
	for index in 0..<y_count {
		if !parse_support(input[y_start + index], &y_values[index]) ||
			!valid_probability(input[y_probability_start + index]) do return -1
		y_probabilities[index] = input[y_probability_start + index]
		for previous in 0..<index {
			if y_values[previous] == y_values[index] do return -1
		}
	}

	required := 3*x_count*y_count
	if required > MAX_OUTPUT_ELEMENTS do return -1
	if output == nil || output_capacity < required do return -2
	position := c.size_t(0)
	for x_index in 0..<x_count {
		for y_index in 0..<y_count {
			output[position] = f64(x_values[x_index])
			output[position + 1] = f64(y_values[y_index])
			output[position + 2] = x_probabilities[x_index] * y_probabilities[y_index]
			position += 3
		}
	}
	return i64(required)
}
