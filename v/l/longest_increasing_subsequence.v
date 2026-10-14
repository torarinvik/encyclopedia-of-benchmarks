module longest_increasing_subsequence

// Return the length of a strictly increasing subsequence.
@[export: 'longest_increasing_subsequence']
pub fn longest_increasing_subsequence(values &i64, length usize) i64 {
	if length > 512 { return -1 }
	mut dp := [512]i64{}
	mut longest := i64(0)
	for index := 0; index < int(length); index++ {
		dp[index] = 1
		for previous := 0; previous < index; previous++ {
			if unsafe { values[index] > values[previous] } && dp[index] < dp[previous] + 1 {
				dp[index] = dp[previous] + 1
			}
		}
		if dp[index] > longest { longest = dp[index] }
	}
	return longest
}
