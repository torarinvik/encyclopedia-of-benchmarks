package thomas_algorithm

import "core:c"

MAX_N :: 32

put_f64_le :: proc "contextless" (output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
thomas_algorithm :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > 1 + 4*MAX_N do return -1
	n_value := input[0]
	if n_value < 1 || n_value > i64(MAX_N) do return -1
	n := int(n_value)
	if length != c.size_t(1+4*n) do return -1

	var lower, diagonal, upper, rhs: [MAX_N]i64
	for row := 0; row < n; row += 1 {
		lower[row] = input[1+row]
		diagonal[row] = input[1+n+row]
		upper[row] = input[1+2*n+row]
		rhs[row] = input[1+3*n+row]
	}
	if lower[0] != 0 || upper[n-1] != 0 do return -1
	for row := 0; row < n; row += 1 {
		if lower[row] < -16 || lower[row] > 16 || upper[row] < -16 || upper[row] > 16 do return -1
		if diagonal[row] < 17 || diagonal[row] > 64 || rhs[row] < -1000 || rhs[row] > 1000 do return -1
		lower_abs := if lower[row] < 0 then -lower[row] else lower[row]
		upper_abs := if upper[row] < 0 then -upper[row] else upper[row]
		if diagonal[row] <= lower_abs+upper_abs do return -1
	}
	output_bytes := n*8
	if output == nil || capacity < c.size_t(output_bytes) do return -2

	var modified_upper, modified_rhs, solution: [MAX_N]f64
	modified_upper[0] = f64(upper[0])/f64(diagonal[0])
	modified_rhs[0] = f64(rhs[0])/f64(diagonal[0])
	for row := 1; row < n; row += 1 {
		pivot := f64(diagonal[row])-f64(lower[row])*modified_upper[row-1]
		if row+1 < n do modified_upper[row] = f64(upper[row])/pivot
		modified_rhs[row] = (f64(rhs[row])-f64(lower[row])*modified_rhs[row-1])/pivot
	}
	solution[n-1] = modified_rhs[n-1]
	row := n-1
	for row > 0 {
		row -= 1
		solution[row] = modified_rhs[row]-modified_upper[row]*solution[row+1]
	}
	for row := 0; row < n; row += 1 { put_f64_le(output, row*8, solution[row]) }
	return i64(output_bytes)
}
