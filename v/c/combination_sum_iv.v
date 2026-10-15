module combination_sum_iv

@[export: 'combination_sum_iv']
pub fn combination_sum_iv(packed &i64, length usize) i64 {
	invalid := i64(-9223372036854775807 - 1)
	if length < 2 || length > 18 { return invalid }
	if unsafe { packed[0] } < 0 || unsafe { packed[0] } > 16 || unsafe { packed[1] } < 0 || unsafe { packed[1] } > 63 { return invalid }
	count := int(unsafe { packed[0] })
	target := int(unsafe { packed[1] })
	if length != usize(count + 2) { return invalid }
	for i in 0 .. count {
		if unsafe { packed[i + 2] } < 1 || unsafe { packed[i + 2] } > 63 { return invalid }
		for j in 0 .. i {
			if unsafe { packed[i + 2] } == unsafe { packed[j + 2] } { return invalid }
		}
	}

	mut dp := [64]i64{}
	dp[0] = 1
	for sum := 1; sum <= target; sum++ {
		for i in 0 .. count {
			denomination := int(unsafe { packed[i + 2] })
			if denomination <= sum {
				dp[sum] += dp[sum - denomination]
			}
		}
	}
	return dp[target]
}
