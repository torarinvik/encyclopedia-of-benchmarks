module adjugate_matrix

const max_n = 6
const modulus = i64(998244353)

fn minor_determinant(matrix []i64, n int, skip_row int, skip_column int) i64 {
	dimension := n - 1
	if dimension == 0 { return 1 }
	mut minor := []i64{len: max_n * max_n}
	mut target_row := 0
	for row in 0 .. n {
		if row == skip_row { continue }
		mut target_column := 0
		for column in 0 .. n {
			if column == skip_column { continue }
			minor[target_row * dimension + target_column] = matrix[row * n + column]
			target_column++
		}
		target_row++
	}

	mut dp := []i64{len: 1 << (max_n - 1)}
	dp[0] = 1
	limit := 1 << dimension
	for mask in 0 .. limit {
		mut row := 0
		mut bits := mask
		for bits != 0 { row += bits & 1; bits >>= 1 }
		if row == dimension { continue }
		for column in 0 .. dimension {
			if (mask & (1 << column)) != 0 { continue }
			mut inversions := 0
			for prior in column + 1 .. dimension { inversions += (mask >> prior) & 1 }
			next := mask | (1 << column)
			term := (dp[mask] * minor[row * dimension + column]) % modulus
			if (inversions & 1) == 0 {
				dp[next] = (dp[next] + term) % modulus
			} else {
				dp[next] = (dp[next] - term + modulus) % modulus
			}
		}
	}
	return dp[limit - 1]
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'adjugate_matrix']
pub fn adjugate_matrix(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > usize(1 + max_n * max_n) { return -1 }
	n_value := unsafe { input[0] }
	if n_value < 1 || n_value > max_n { return -1 }
	n := int(n_value)
	if length != usize(1 + n * n) { return -1 }

	mut matrix := []i64{len: max_n * max_n}
	for index in 0 .. n * n {
		value := unsafe { input[1 + index] }
		if value < 0 || value >= modulus { return -1 }
		matrix[index] = value
	}

	output_bytes := 8 * n * n
	if unsafe { output == nil } || capacity < usize(output_bytes) { return -2 }
	for row in 0 .. n {
		for column in 0 .. n {
			mut value := minor_determinant(matrix, n, column, row)
			if (row + column) % 2 == 1 && value != 0 { value = modulus - value }
			store_i64_le(mut output, 8 * (row * n + column), value)
		}
	}
	return i64(output_bytes)
}
