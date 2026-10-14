package longest_common_subsequence

import "core:c"

// Return the LCS length of two packed ASCII sequences.
@(export)
longest_common_subsequence :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed == nil || length < 2 || length > 512 do return -1
	left_length := packed[0]
	right_length := packed[1]
	if left_length < 0 || left_length > 255 || right_length < 0 || right_length > 255 do return -1
	if length != c.size_t(2 + left_length + right_length) do return -1
	for index := c.size_t(0); index < c.size_t(left_length + right_length); index += 1 {
		if packed[2 + index] < 0 || packed[2 + index] > 127 do return -1
	}

	dp: [256]i64
	for index := 0; index < 256; index += 1 {
		dp[index] = 0
	}
	for left := 0; left < int(left_length); left += 1 {
		diagonal := i64(0)
		for right := 1; right <= int(right_length); right += 1 {
			above := dp[right]
			if packed[2 + c.size_t(left)] == packed[2 + c.size_t(left_length) + c.size_t(right) - 1] {
				dp[right] = diagonal + 1
			} else if dp[right - 1] > dp[right] {
				dp[right] = dp[right - 1]
			}
			diagonal = above
		}
	}
	return dp[int(right_length)]
}
