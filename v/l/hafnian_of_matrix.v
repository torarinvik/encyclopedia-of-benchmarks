module hafnian_of_matrix

const max_n = 16
const max_input_values = 1 + max_n * max_n
const states = 1 << max_n
const modulus = i64(998244353)

fn store_i64_le(mut output &u8, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'hafnian_of_matrix']
pub fn hafnian_of_matrix(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_values { return -1 }
	n_value := unsafe { input[0] }
	if n_value < 2 || n_value > max_n || n_value % 2 != 0 { return -1 }
	n := int(n_value)
	if length != usize(1 + n * n) { return -1 }

	mut matrix := []i64{len: max_n * max_n}
	for row in 0 .. n {
		for column in 0 .. n {
			value := unsafe { input[1 + row * n + column] }
			if value < 0 || value >= modulus || (row == column && value != 0) { return -1 }
			matrix[row * max_n + column] = value
		}
	}
	for row in 0 .. n {
		for column in 0 .. row {
			if matrix[row * max_n + column] != matrix[column * max_n + row] { return -1 }
		}
	}

	mut dp := []i64{len: states}
	dp[0] = 1
	mut full := 1
	for _ in 0 .. n { full *= 2 }
	full--
	for mask in 1 .. full + 1 {
		mut bits := mask
		mut parity := 0
		for bits > 0 {
			parity = (parity + bits % 2) % 2
			bits /= 2
		}
		if parity != 0 { continue }
		mut first := 0
		for (mask / (1 << first)) % 2 == 0 { first++ }
		without_first := mask - (1 << first)
		for second in first + 1 .. n {
			if (without_first / (1 << second)) % 2 == 0 { continue }
			rest := without_first - (1 << second)
			dp[mask] = (dp[mask] + matrix[first * max_n + second] * dp[rest]) % modulus
		}
	}
	if unsafe { output == nil } || capacity < 8 { return -2 }
	store_i64_le(mut output, dp[full])
	return 8
}
