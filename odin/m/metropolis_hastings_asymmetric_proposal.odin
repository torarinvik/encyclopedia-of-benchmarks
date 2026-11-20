package metropolis_hastings_asymmetric_proposal

import "core:c"

MAX_STATES :: 8
MAX_STEPS :: 64
MAX_INPUT :: 267
MAX_OUTPUT :: 65

@(export)
metropolis_hastings_asymmetric_proposal :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	n64, steps64, initial64 := input[0], input[1], input[2]
	if n64 < 2 || n64 > MAX_STATES || steps64 < 0 || steps64 > MAX_STEPS ||
		initial64 < 0 || initial64 >= n64 do return -1
	n, steps := int(n64), int(steps64)
	weights_start := 3
	matrix_start := weights_start + n
	proposals_start := matrix_start + n*n
	draws_start := proposals_start + steps
	if length != c.size_t(draws_start + 2*steps) do return -1
	for state := 0; state < n; state += 1 {
		weight := input[weights_start + state]
		if weight < 1 || weight > 1024 do return -1
	}
	for row := 0; row < n; row += 1 {
		row_sum := i64(0)
		for column := 0; column < n; column += 1 {
			q := input[matrix_start + row*n + column]
			if q < 0 || q > 1024 do return -1
			row_sum += q
		}
		if row_sum != 1024 do return -1
	}

	staged: [MAX_OUTPUT]u8
	current := int(initial64)
	staged[0] = u8(current)
	for step := 0; step < steps; step += 1 {
		proposal64 := input[proposals_start + step]
		draw_num := input[draws_start + 2*step]
		draw_den := input[draws_start + 2*step + 1]
		if proposal64 < 0 || proposal64 >= n64 || draw_den < 1 || draw_den > 1024 ||
			draw_num < 0 || draw_num >= draw_den do return -1
		proposal := int(proposal64)
		forward := input[matrix_start + current*n + proposal]
		if forward == 0 do return -1
		reverse := input[matrix_start + proposal*n + current]
		numerator := input[weights_start + proposal] * reverse
		denominator := input[weights_start + current] * forward
		if numerator >= denominator || draw_num*denominator < draw_den*numerator do current = proposal
		staged[step + 1] = u8(current)
	}

	needed := steps + 1
	if output == nil || capacity < c.size_t(needed) do return -2
	for index := 0; index < needed; index += 1 { output[index] = staged[index] }
	return i64(needed)
}
