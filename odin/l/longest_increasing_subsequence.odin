package longest_increasing_subsequence

import "core:c"

// Return the length of a strictly increasing subsequence.
@(export)
longest_increasing_subsequence :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > 512 do return -1
	dp: [512]i64
	longest := i64(0)
	for index := 0; index < int(length); index += 1 {
		dp[index] = 1
		for previous := 0; previous < index; previous += 1 {
			if values[index] > values[previous] && dp[index] < dp[previous] + 1 {
				dp[index] = dp[previous] + 1
			}
		}
		if dp[index] > longest do longest = dp[index]
	}
	return longest
}
