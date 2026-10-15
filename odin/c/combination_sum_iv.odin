package combination_sum_iv

import "core:c"

// Bottom-up count of ordered denomination sequences.
@(export)
combination_sum_iv :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	invalid := i64(-9223372036854775807 - 1)
	if length < 2 || length > 18 do return invalid
	if packed[0] < 0 || packed[0] > 16 || packed[1] < 0 || packed[1] > 63 do return invalid
	count := int(packed[0])
	target := int(packed[1])
	if length != c.size_t(count + 2) do return invalid
	for i := 0; i < count; i += 1 {
		if packed[i + 2] < 1 || packed[i + 2] > 63 do return invalid
		for j := 0; j < i; j += 1 {
			if packed[i + 2] == packed[j + 2] do return invalid
		}
	}

	dp: [64]i64 = {}
	dp[0] = 1
	for sum := 1; sum <= target; sum += 1 {
		for i := 0; i < count; i += 1 {
			denomination := int(packed[i + 2])
			if denomination <= sum {
				dp[sum] += dp[sum - denomination]
			}
		}
	}
	return dp[target]
}
