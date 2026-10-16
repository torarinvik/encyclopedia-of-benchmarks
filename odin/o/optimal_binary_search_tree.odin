package optimal_binary_search_tree

import "core:c"

@(export)
optimal_binary_search_tree :: proc "c" (v: [^]i64, n: c.size_t) -> i64 {
	if v == nil || n < 2 || n > 33 || v[0] < 1 || v[0] > 32 || int(n) != int(v[0])+1 do return -1
	k := int(v[0]); prefix: [33]i64; dp: [32][32]i64
	for i := 0; i < k; i += 1 { f := v[i+1]; if f < 0 || f > 1000 do return -1; prefix[i+1] = prefix[i]+f; dp[i][i] = f }
	for width := 2; width <= k; width += 1 { for start := 0; start+width <= k; start += 1 {
		finish := start+width-1; total := prefix[finish+1]-prefix[start]; best: i64 = 1000000000
		for root := start; root <= finish; root += 1 { cost := total; if root > start { cost += dp[start][root-1] }; if root < finish { cost += dp[root+1][finish] }; if cost < best { best = cost } }
		dp[start][finish] = best
	} }
	return dp[0][k-1]
}
