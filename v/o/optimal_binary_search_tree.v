module optimal_binary_search_tree

@[export: 'optimal_binary_search_tree']
pub fn optimal_binary_search_tree(values &i64, length usize) i64 {
	if length < 2 || length > 33 { return -1 }
	count := unsafe { values[0] }
	if count < 1 || count > 32 || length != usize(count+1) { return -1 }
	mut prefix := [33]i64{}; mut dp := [32][32]i64{}
	for i in 0 .. int(count) { f := unsafe { values[i+1] }; if f < 0 || f > 1000 { return -1 }; prefix[i+1] = prefix[i]+f; dp[i][i] = f }
	for width in 2 .. int(count)+1 { for start in 0 .. int(count)-width+1 {
		finish := start+width-1; total := prefix[finish+1]-prefix[start]; mut best := i64(1000000000)
		for root in start .. finish+1 { mut cost := total; if root > start { cost += dp[start][root-1] }; if root < finish { cost += dp[root+1][finish] }; if cost < best { best = cost } }
		dp[start][finish] = best
	} }
	return dp[0][int(count)-1]
}
