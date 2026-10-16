package wildcard_matching

import "core:c"

// Full-string wildcard matching for lowercase ASCII text.
@(export)
wildcard_matching :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 35 do return -1
	if input[0] < 0 || input[0] > 12 || input[1] < 0 || input[1] > 20 do return -1
	text_length := int(input[0])
	pattern_length := int(input[1])
	if int(length) != 2 + text_length + pattern_length do return -1
	for i := 0; i < text_length; i += 1 {
		if input[2 + i] < 97 || input[2 + i] > 122 do return -1
	}
	pattern_start := 2 + text_length
	for j := 0; j < pattern_length; j += 1 {
		token := input[pattern_start + j]
		if !((token >= 97 && token <= 122) || token == 42 || token == 63) do return -1
	}

	dp: [13][21]bool = {}
	dp[0][0] = true
	for j := 1; j <= pattern_length; j += 1 {
		if input[pattern_start + j - 1] == 42 do dp[0][j] = dp[0][j - 1]
	}
	for i := 1; i <= text_length; i += 1 {
		for j := 1; j <= pattern_length; j += 1 {
			token := input[pattern_start + j - 1]
			if token == input[1 + i] || token == 63 {
				dp[i][j] = dp[i - 1][j - 1]
			} else if token == 42 {
				dp[i][j] = dp[i - 1][j] || dp[i][j - 1]
			}
		}
	}
	return i64(dp[text_length][pattern_length])
}
