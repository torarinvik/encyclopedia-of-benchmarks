package adjugate_matrix

import "core:c"

MAX_N :: 6
MODULUS :: i64(998244353)

minor_determinant :: proc "contextless" (matrix: [MAX_N * MAX_N]i64, n, skip_row, skip_column: int) -> i64 {
	dimension := n - 1
	if dimension == 0 do return 1
	minor: [MAX_N * MAX_N]i64
	target_row := 0
	for row := 0; row < n; row += 1 {
		if row == skip_row do continue
		target_column := 0
		for column := 0; column < n; column += 1 {
			if column == skip_column do continue
			minor[target_row * dimension + target_column] = matrix[row * n + column]
			target_column += 1
		}
		target_row += 1
	}

	dp: [1 << (MAX_N - 1)]i64 = {}
	dp[0] = 1
	limit := 1 << dimension
	for mask := 0; mask < limit; mask += 1 {
		row := 0
		bits := mask
		for bits != 0 { row += bits & 1; bits >>= 1 }
		if row == dimension do continue
		for column := 0; column < dimension; column += 1 {
			if (mask & (1 << column)) != 0 do continue
			inversions := 0
			for prior := column + 1; prior < dimension; prior += 1 {
				inversions += (mask >> prior) & 1
			}
			next := mask | (1 << column)
			term := (dp[mask] * minor[row * dimension + column]) % MODULUS
			if (inversions & 1) == 0 {
				dp[next] = (dp[next] + term) % MODULUS
			} else {
				dp[next] = (dp[next] - term + MODULUS) % MODULUS
			}
		}
	}
	return dp[limit - 1]
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
adjugate_matrix :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 1 + MAX_N * MAX_N do return -1
	n_value := input[0]
	if n_value < 1 || n_value > i64(MAX_N) do return -1
	n := int(n_value)
	if length != c.size_t(1 + n * n) do return -1

	matrix: [MAX_N * MAX_N]i64
	for index := 0; index < n * n; index += 1 {
		value := input[1 + index]
		if value < 0 || value >= MODULUS do return -1
		matrix[index] = value
	}

	output_bytes := 8 * n * n
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for row := 0; row < n; row += 1 {
		for column := 0; column < n; column += 1 {
			value := minor_determinant(matrix, n, column, row)
			if (row + column) % 2 == 1 && value != 0 do value = MODULUS - value
			store_i64_le(output, 8 * (row * n + column), value)
		}
	}
	return i64(output_bytes)
}
