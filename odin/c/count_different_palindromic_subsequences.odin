package count_different_palindromic_subsequences

import "core:c"

MAX_LENGTH :: 20
MODULUS :: i64(1_000_000_007)

normalize :: proc(value: i64) -> i64 {
	result := value % MODULUS
	if result < 0 do result += MODULUS
	return result
}

@(export)
count_different_palindromic_subsequences :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_LENGTH + 2 do return -1
	n_value := input[0]
	if n_value < 0 || n_value > MAX_LENGTH || int(length) != int(n_value) + 1 do return -1
	n := int(n_value)
	symbols: [MAX_LENGTH]int
	symbols = {}
	for i := 0; i < n; i += 1 {
		if input[i + 1] < 0 || input[i + 1] > 3 do return -1
		symbols[i] = int(input[i + 1])
	}
	if n == 0 do return 0

	next_equal, previous_equal: [MAX_LENGTH]int
	next_at: [4]int
	previous_at: [4]int
	for symbol := 0; symbol < 4; symbol += 1 {
		next_at[symbol] = n
		previous_at[symbol] = -1
	}
	for i := n; i > 0; i -= 1 {
		index := i - 1
		symbol := symbols[index]
		next_equal[index] = next_at[symbol]
		next_at[symbol] = index
	}
	for i := 0; i < n; i += 1 {
		symbol := symbols[i]
		previous_equal[i] = previous_at[symbol]
		previous_at[symbol] = i
	}

	dp: [MAX_LENGTH][MAX_LENGTH]i64
	dp = {}
	for i := 0; i < n; i += 1 do dp[i][i] = 1
	for width := 2; width <= n; width += 1 {
		for left := 0; left + width <= n; left += 1 {
			right := left + width - 1
			inner := i64(0)
			if width > 2 do inner = dp[left + 1][right - 1]
			if symbols[left] != symbols[right] {
				dp[left][right] = normalize(dp[left + 1][right] + dp[left][right - 1] - inner)
			} else {
				first := next_equal[left]
				last := previous_equal[right]
				value := i64(0)
				if first >= right || last <= left || first > last {
					value = 2 * inner + 2
				} else if first == last {
					value = 2 * inner + 1
				} else {
					duplicates := i64(0)
					if first + 1 <= last - 1 do duplicates = dp[first + 1][last - 1]
					value = 2 * inner - duplicates
				}
				dp[left][right] = normalize(value)
			}
		}
	}
	return dp[0][n - 1]
}
