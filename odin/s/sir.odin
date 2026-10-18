package sir

import "core:c"

INVALID_RESULT :: -1
OUTPUT_ERROR :: -2
INPUT_LENGTH :: 6
MAX_PARSEABLE_INPUT_LENGTH :: 7

in_range :: proc(value, minimum, maximum: f64) -> bool {
	return value >= minimum && value <= maximum
}

@(export)
sir :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < c.size_t(INPUT_LENGTH) ||
		input_length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) do return INVALID_RESULT
	if input_length != c.size_t(INPUT_LENGTH) do return INVALID_RESULT

	s, i, r, beta, k, time := input[0], input[1], input[2], input[3], input[4], input[5]
	if !in_range(s, 0, 1_000_000) || !in_range(i, 0, 1_000_000) ||
		!in_range(r, 0, 1_000_000) || !in_range(beta, 0, 0.001) ||
		!in_range(k, 0, 1) || !in_range(time, 0, 140) do return INVALID_RESULT

	d_s := ((-beta) * s) * i
	d_i_infection := (beta * s) * i
	d_i_recovery := k * i
	d_i := d_i_infection - d_i_recovery
	d_r := k * i

	if output == nil || output_capacity < 3 do return OUTPUT_ERROR
	output[0] = d_s
	output[1] = d_i
	output[2] = d_r
	return 3
}
