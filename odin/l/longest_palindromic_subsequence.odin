package longest_palindromic_subsequence

import "core:c"

MAX_VALUES :: 128

@(export)
longest_palindromic_subsequence :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > c.size_t(MAX_VALUES) do return -1
	if length == 0 do return 0
	dp: [MAX_VALUES]i64
	for index := 0; index < MAX_VALUES; index += 1 { dp[index] = 0 }
	start := int(length)
	for start > 0 {
		start -= 1
		dp[start] = 1
		diagonal := i64(0)
		for finish := start + 1; finish < int(length); finish += 1 {
			previous := dp[finish]
			if values[start] == values[finish] {
				dp[finish] = diagonal + 2
			} else {
				if dp[finish] < dp[finish - 1] { dp[finish] = dp[finish - 1] }
			}
			diagonal = previous
		}
	}
	return dp[int(length) - 1]
}
