package gaussian_elimination

import "core:c"

put_f64_le :: proc "contextless" (output: [^]u8, offset: usize, value: f64) {
	bits := transmute(u64)value
	for b: usize = 0; b < 8; b += 1 { output[offset+b] = u8(bits >> u64(8*b)) }
}

@(export)
gaussian_elimination :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 do return -1
	if input[0] < 2 || input[0] > 8 do return -1
	n := int(input[0])
	if length != c.size_t(1+n*n+n) do return -1
	var matrix: [8][9]f64
	for row: int = 0; row < n; row += 1 {
		for col: int = 0; col < n; col += 1 {
			value := input[1+row*n+col]
			if (row == col && value != 32) || (row != col && value != 0 && value != -1) do return -1
			if (row+1 < col || col+1 < row) && value != 0 do return -1
			if row != col && value != input[1+col*n+row] do return -1
			matrix[row][col] = f64(value)
		}
		rhs := input[1+n*n+row]
		if rhs < -100 || rhs > 100 do return -1
		matrix[row][n] = f64(rhs)
	}
	if output == nil || capacity < c.size_t(n*8) do return -2
	for step: int = 0; step < n-1; step += 1 {
		for row: int = step+1; row < n; row += 1 {
			factor := matrix[row][step] / matrix[step][step]
			for col: int = step; col <= n; col += 1 { matrix[row][col] -= factor * matrix[step][col] }
		}
	}
	var solution: [8]f64
	for row := n-1; row >= 0; row -= 1 {
		sum: f64 = 0
		for col := row+1; col < n; col += 1 { sum += matrix[row][col] * solution[col] }
		solution[row] = (matrix[row][n] - sum) / matrix[row][row]
	}
	for i: int = 0; i < n; i += 1 { put_f64_le(output, usize(i*8), solution[i]) }
	return i64(n*8)
}
