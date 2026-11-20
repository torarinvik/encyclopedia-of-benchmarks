package strange_printer

import "core:c"

MAX_LENGTH :: 8
TABLE_SIDE :: 9

@(export, link_name="strange_printer")
strange_printer :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 10 do return -1
	n_value := input[0]
	if n_value < 0 || n_value > MAX_LENGTH || length != c.size_t(n_value + 1) do return -1
	n := int(n_value)
	for position := 0; position < n; position += 1 {
		if input[position + 1] < 0 || input[position + 1] > 2 do return -1
	}
	if n == 0 do return 0

	dp: [TABLE_SIDE * TABLE_SIDE]i64
	for left := n - 1; left >= 0; left -= 1 {
		dp[left * TABLE_SIDE + left] = 1
		for right := left + 1; right < n; right += 1 {
			best := dp[(left + 1) * TABLE_SIDE + right] + 1
			for merge := left + 1; merge <= right; merge += 1 {
				if input[left + 1] != input[merge + 1] do continue
				middle: i64 = 0
				if merge > left + 1 do middle = dp[(left + 1) * TABLE_SIDE + merge - 1]
				candidate := middle + dp[merge * TABLE_SIDE + right]
				if candidate < best do best = candidate
			}
			dp[left * TABLE_SIDE + right] = best
		}
	}
	return dp[n - 1]
}
