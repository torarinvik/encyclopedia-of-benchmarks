package unique_subsequences_count

import "core:c"

@(export)
unique_subsequences_count :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length < 1 || length > 31 do return -1
	n_value := input[0]
	if n_value < 0 || n_value > 30 || length != c.size_t(n_value + 1) do return -1
	n := int(n_value)
	for i := 0; i < n; i += 1 {
		if input[i + 1] < 0 || input[i + 1] > 127 do return -1
	}
	dp: [31]i64 = {}
	end := n
	for end > 0 {
		i := end - 1
		seen: [128]bool = {}
		for j := i; j < n; j += 1 {
			ch := int(input[j + 1])
			if !seen[ch] {
				seen[ch] = true
				dp[i] += 1 + dp[j + 1]
			}
		}
		end -= 1
	}
	return dp[0]
}
