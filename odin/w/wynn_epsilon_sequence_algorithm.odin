package wynn_epsilon_sequence_algorithm

import "core:c"
import "core:math"

MAX_N :: 10
MAX_INPUT_LENGTH :: 13
MAX_ORDER :: 6

@(export)
wynn_epsilon_sequence_algorithm :: proc "c" (input: [^]f64, input_length: c.size_t,
        output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 3 || input_length > MAX_INPUT_LENGTH do return -1
	for i in 0..<int(input_length) { if !math.is_finite(input[i]) do return -1 }
	n_value, k_value := input[0], input[1]
	if math.trunc(n_value) != n_value || math.trunc(k_value) != k_value ||
		n_value < 5 || n_value > f64(MAX_N) || k_value < 2 || k_value > 3 do return -1
	n, k := int(n_value), int(k_value)
	if n < 2*k+1 || input_length != c.size_t(n+2) do return -1
	for i in 0..<n {
		sample := input[i+2]
		scaled := sample*256.0
		if sample < -2 || sample > 2 || math.trunc(scaled) != scaled do return -1
	}

	var rows: [MAX_ORDER+1][MAX_N]f64 = {}
	var valid: [MAX_ORDER+1][MAX_N]bool = {}
	for i in 0..<n { rows[0][i] = input[i+2]; valid[0][i] = true }
	for order in 0..<2*k {
		for i in 0..<n-order-1 {
			auxiliary_valid := true
			if order != 0 { auxiliary_valid = valid[order-1][i+1] }
			if !valid[order][i] || !valid[order][i+1] || !auxiliary_valid do continue
			denominator := rows[order][i+1] - rows[order][i]
			if denominator == 0 || !math.is_finite(denominator) do continue
			reciprocal := 1.0/denominator
			auxiliary := f64(0)
			if order != 0 { auxiliary = rows[order-1][i+1] }
			value := auxiliary + reciprocal
			if !math.is_finite(reciprocal) || !math.is_finite(value) do continue
			rows[order+1][i] = value
			valid[order+1][i] = true
		}
	}

	needed := 0
	for order := 2; order <= 2*k; order += 2 { needed += 2*(n-order) }
	if output == nil || output_capacity < c.size_t(needed) do return -2
	cursor := 0
	for order := 2; order <= 2*k; order += 2 {
		for i in 0..<n-order {
			if valid[order][i] { output[cursor] = 0; output[cursor+1] = rows[order][i] }
			else { output[cursor] = 1; output[cursor+1] = 0 }
			cursor += 2
		}
	}
	return i64(needed)
}
