module knuth_optimized_optimal_binary_search_tree

const max_n = 64
const max_input = 65
const max_frequency = i64(1_000_000)

@[export: 'knuth_optimized_optimal_binary_search_tree']
pub fn knuth_optimized_optimal_binary_search_tree(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length < 2 || length > max_input { return -1 }
		nv := values[0]
		if nv < 1 || nv > max_n || length != usize(nv+1) { return -1 }
		n := int(nv)
		mut prefix := [65]i64{}
		mut dp := [64][64]i64{}
		mut opt := [64][64]int{}
		for i in 0 .. n {
			f := values[i+1]
			if f < 0 || f > max_frequency { return -1 }
			prefix[i+1] = prefix[i]+f; dp[i][i] = f; opt[i][i] = i
		}
		for width in 2 .. n+1 {
			for left in 0 .. n-width+1 {
				right := left+width-1; first := opt[left][right-1]; last := opt[left+1][right]
				total := prefix[right+1]-prefix[left]; mut best := i64(0x7fffffffffffffff); mut best_root := first
				for root in first .. last+1 {
					mut cost := total
					if root > left { cost += dp[left][root-1] }
					if root < right { cost += dp[root+1][right] }
					if cost < best { best = cost; best_root = root }
				}
				dp[left][right] = best; opt[left][right] = best_root
			}
		}
		return dp[0][n-1]
	}
}
