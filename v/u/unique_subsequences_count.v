module unique_subsequences_count

@[export: 'unique_subsequences_count']
pub fn unique_subsequences_count(input &i64, length usize) i64 {
	if length == 0 || length > 31 { return -1 }
	n_value := unsafe { input[0] }
	if n_value < 0 || n_value > 30 || length != usize(n_value + 1) { return -1 }
	n := int(n_value)
	for i in 0 .. n {
		value := unsafe { input[i + 1] }
		if value < 0 || value > 127 { return -1 }
	}
	mut dp := [31]i64{}
	mut end_index := n
	for end_index > 0 {
		i := end_index - 1
		mut seen := [128]bool{}
		for j := i; j < n; j++ {
			ch := int(unsafe { input[j + 1] })
			if !seen[ch] {
				seen[ch] = true
				dp[i] += 1 + dp[j + 1]
			}
		}
		end_index--
	}
	return dp[0]
}
