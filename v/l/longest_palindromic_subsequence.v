module longest_palindromic_subsequence

const max_values = 128

@[export: 'longest_palindromic_subsequence']
pub fn longest_palindromic_subsequence(values &i64, length usize) i64 {
	if length > max_values { return -1 }
	if length == 0 { return 0 }
	mut dp := [128]i64{}
	mut start := length
	for start > 0 {
		start--
		dp[start] = 1
		mut diagonal := i64(0)
		for finish := start + 1; finish < length; finish++ {
			previous := dp[finish]
			if unsafe { values[start] == values[finish] } {
				dp[finish] = diagonal + 2
			} else {
				if dp[finish] < dp[finish - 1] { dp[finish] = dp[finish - 1] }
			}
			diagonal = previous
		}
	}
	return dp[length - 1]
}
