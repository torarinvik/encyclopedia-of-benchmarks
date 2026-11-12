package knuth_optimized_optimal_binary_search_tree

MAX_N :: 64
MAX_INPUT :: 65
MAX_FREQUENCY :: i64(1_000_000)

knuth_optimized_optimal_binary_search_tree :: proc "c" (v: [^]i64, length: c.size_t) -> i64 {
	if v == nil || length < 2 || length > MAX_INPUT do return -1
	nv := v[0]
	if nv < 1 || nv > MAX_N || int(length) != int(nv)+1 do return -1
	n := int(nv)
	prefix: [65]i64 = {}
	dp: [64][64]i64 = {}
	opt: [64][64]int = {}
	for i := 0; i < n; i += 1 {
		f := v[i+1]
		if f < 0 || f > MAX_FREQUENCY do return -1
		prefix[i+1] = prefix[i]+f; dp[i][i] = f; opt[i][i] = i
	}
	for width := 2; width <= n; width += 1 {
		for left := 0; left+width <= n; left += 1 {
			right := left+width-1; first := opt[left][right-1]; last := opt[left+1][right]
			total := prefix[right+1]-prefix[left]; best := i64(0x7fffffffffffffff); best_root := first
			for root := first; root <= last; root += 1 {
				cost := total; if root > left { cost += dp[left][root-1] }; if root < right { cost += dp[root+1][right] }
				if cost < best { best = cost; best_root = root }
			}
			dp[left][right] = best; opt[left][right] = best_root
		}
	}
	return dp[0][n-1]
}
