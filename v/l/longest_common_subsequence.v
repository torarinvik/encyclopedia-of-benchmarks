module longest_common_subsequence

// Return the LCS length of two packed ASCII sequences.
@[export: 'longest_common_subsequence']
pub fn longest_common_subsequence(packed &i64, length usize) i64 {
	if length < 2 || length > 512 { return -1 }
	left_length := unsafe { packed[0] }
	right_length := unsafe { packed[1] }
	if left_length < 0 || left_length > 255 || right_length < 0 || right_length > 255 { return -1 }
	if length != usize(2 + left_length + right_length) { return -1 }
	for index in 0 .. usize(left_length + right_length) {
		value := unsafe { packed[2 + index] }
		if value < 0 || value > 127 { return -1 }
	}

	mut dp := [256]i64{init: 0}
	for left in 0 .. usize(left_length) {
		mut diagonal := i64(0)
		for right in 1 .. usize(right_length) + 1 {
			above := dp[right]
			if unsafe { packed[2 + left] } == unsafe { packed[2 + usize(left_length) + right - 1] } {
				dp[right] = diagonal + 1
			} else if dp[right - 1] > dp[right] {
				dp[right] = dp[right - 1]
			}
			diagonal = above
		}
	}
	return dp[int(right_length)]
}
