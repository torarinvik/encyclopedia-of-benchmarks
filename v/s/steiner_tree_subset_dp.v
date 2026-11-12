module steiner_tree_subset_dp

const max_n = 8
const max_m = 14
const max_k = 5
const max_input = 50
const max_masks = 1 << max_k
const inf = i64(1000000000000000000)

@[export: 'steiner_tree_subset_dp']
pub fn steiner_tree_subset_dp(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		n0 := input[0]; m0 := input[1]; k0 := input[2]
		if n0 < 1 || n0 > 8 || m0 < 0 || m0 > 14 || k0 < 1 || k0 > 5 || k0 > n0 { return -1 }
		n := int(n0); m := int(m0); k := int(k0)
		if m > n * (n - 1) / 2 || length != usize(3 + k + 3 * m) { return -1 }
		mut terminal_seen := [max_n]bool{}
		mut terminals := [max_k]int{}
		for i in 0 .. k {
			raw := input[3 + i]
			if raw < 0 || raw >= n0 || terminal_seen[int(raw)] { return -1 }
			terminal_seen[int(raw)] = true
			terminals[i] = int(raw)
		}
		mut present := [max_n][max_n]bool{}
		mut weights := [max_n][max_n]i64{init: 0}
		for i in 0 .. m {
			u0 := input[3 + k + 3 * i]; v0 := input[4 + k + 3 * i]; w := input[5 + k + 3 * i]
			if u0 < 0 || u0 >= v0 || v0 >= n0 || w < 0 || w > 1000 { return -1 }
			u := int(u0); v := int(v0)
			if present[u][v] { return -1 }
			present[u][v] = true; present[v][u] = true
			weights[u][v] = w; weights[v][u] = w
		}
		mut dp := [max_masks][max_n]i64{init: inf}
		for bit in 0 .. k { dp[1 << bit][terminals[bit]] = 0 }
		masks := 1 << k
		for mask in 1 .. masks {
			if (mask & (mask - 1)) != 0 {
				mut sub := (mask - 1) & mask
				for sub > 0 {
					other := mask ^ sub
					if sub < other {
						for v in 0 .. n {
							left := dp[sub][v]; right := dp[other][v]
							if left < inf && right < inf && left + right < dp[mask][v] { dp[mask][v] = left + right }
						}
					}
					sub = (sub - 1) & mask
				}
			}
			mut used := [max_n]bool{}
			for _ in 0 .. n {
				mut chosen := -1
				for v in 0 .. n { if !used[v] && (chosen < 0 || dp[mask][v] < dp[mask][chosen]) { chosen = v } }
				if chosen < 0 || dp[mask][chosen] >= inf { break }
				used[chosen] = true
				for v in 0 .. n {
					if present[chosen][v] && !used[v] {
						candidate := dp[mask][chosen] + weights[chosen][v]
						if candidate < dp[mask][v] { dp[mask][v] = candidate }
					}
				}
			}
		}
		mut answer := inf
		for v in 0 .. n { if dp[masks - 1][v] < answer { answer = dp[masks - 1][v] } }
		if answer >= inf { return -2 }
		return answer
	}
}
