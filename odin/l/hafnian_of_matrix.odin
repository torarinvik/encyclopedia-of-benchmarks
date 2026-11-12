package hafnian_of_matrix

import "core:c"

MAX_N :: 16
MAX_INPUT_VALUES :: 1 + MAX_N * MAX_N
STATES :: 1 << MAX_N
MODULUS :: i64(998_244_353)

store_i64_le :: proc "contextless" (output: [^]u8, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[byte] = u8(bits >> u64(8 * byte))
	}
}

@(export)
hafnian_of_matrix :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_VALUES do return -1
	n_value := input[0]
	if n_value < 2 || n_value > i64(MAX_N) || n_value % 2 != 0 do return -1
	n := int(n_value)
	if length != c.size_t(1 + n * n) do return -1

	matrix: [MAX_N * MAX_N]i64
	for row := 0; row < n; row += 1 {
		for column := 0; column < n; column += 1 {
			value := input[1 + row * n + column]
			if value < 0 || value >= MODULUS || (row == column && value != 0) do return -1
			matrix[row * MAX_N + column] = value
		}
	}
	for row := 0; row < n; row += 1 {
		for column := 0; column < row; column += 1 {
			if matrix[row * MAX_N + column] != matrix[column * MAX_N + row] do return -1
		}
	}

	dp: [STATES]i64
	for mask := 0; mask < STATES; mask += 1 do dp[mask] = 0
	dp[0] = 1
	full := 1
	for _ := 0; _ < n; _ += 1 do full *= 2
	full -= 1
	for mask := 1; mask <= full; mask += 1 {
		bits := mask
		parity := 0
		for bits > 0 {
			parity = (parity + bits % 2) % 2
			bits /= 2
		}
		if parity != 0 do continue
		first := 0
		for (mask / (1 << first)) % 2 == 0 do first += 1
		without_first := mask - (1 << first)
		for second := first + 1; second < n; second += 1 {
			if (without_first / (1 << second)) % 2 == 0 do continue
			rest := without_first - (1 << second)
			dp[mask] = (dp[mask] + matrix[first * MAX_N + second] * dp[rest]) % MODULUS
		}
	}
	if output == nil || capacity < 8 do return -2
	store_i64_le(output, dp[full])
	return 8
}
