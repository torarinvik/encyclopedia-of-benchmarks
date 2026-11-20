package lanczos_symmetric_tridiagonalization

import "core:c"
import "core:math"

MAX_PARSEABLE_INPUT_LENGTH :: 19
MAX_ORDER :: 4

finite :: proc(value: f64) -> bool { return math.is_finite(value) }

exact_integer :: proc(value: f64, low, high: i64) -> (i64, bool) {
	if !finite(value) || value < f64(low) || value > f64(high) || f64(i64(value)) != value do return 0, false
	return i64(value), true
}

@(export)
lanczos_symmetric_tridiagonalization :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 3 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	for index: c.size_t = 0; index < input_length; index += 1 { if !finite(input[index]) do return -1 }
	n, valid_n := exact_integer(input[0], 1, MAX_ORDER)
	k, valid_k := exact_integer(input[1], 1, MAX_ORDER)
	if !valid_n || !valid_k || k > n || input_length != c.size_t(2+n*n) do return -1
	for row: i64 = 0; row < n; row += 1 {
		for col: i64 = 0; col < n; col += 1 {
			_, valid_entry := exact_integer(input[2+row*n+col], -4, 4)
			if !valid_entry || input[2+row*n+col] != input[2+col*n+row] do return -1
		}
	}
	required := 2*k
	if output == nil || output_capacity < c.size_t(required) do return -2
	var previous: [4]f64 = {}
	var current: [4]f64 = {}
	var product: [4]f64 = {}
	var residual: [4]f64 = {}
	var next: [4]f64 = {}
	var diagonal: [4]f64 = {}
	var off_diagonal: [3]f64 = {}
	current[0] = 1
	previous_beta: f64 = 0
	for step: i64 = 0; step < k; step += 1 {
		for row: i64 = 0; row < n; row += 1 {
			product[row] = 0
			for col: i64 = 0; col < n; col += 1 { product[row] += input[2+row*n+col]*current[col] }
		}
		alpha: f64 = 0
		for index: i64 = 0; index < n; index += 1 { alpha += current[index]*product[index] }
		if !finite(alpha) do return -3
		diagonal[step] = alpha
		if step+1 == k do break
		norm_squared: f64 = 0
		for index: i64 = 0; index < n; index += 1 {
			residual[index] = product[index]-alpha*current[index]-previous_beta*previous[index]
			norm_squared += residual[index]*residual[index]
		}
		if !finite(norm_squared) || norm_squared < 0 do return -3
		beta := math.sqrt(norm_squared)
		if !finite(beta) || beta <= 9.094947017729282e-13 do return -3
		off_diagonal[step] = beta
		for index: i64 = 0; index < n; index += 1 { next[index] = residual[index]/beta }
		for index: i64 = 0; index < n; index += 1 { previous[index] = current[index] }
		for index: i64 = 0; index < n; index += 1 { current[index] = next[index] }
		previous_beta = beta
	}
	output[0] = f64(k)
	for index: i64 = 0; index < k; index += 1 { output[1+index] = diagonal[index] }
	for index: i64 = 0; index < k-1; index += 1 { output[1+k+index] = off_diagonal[index] }
	return required
}
