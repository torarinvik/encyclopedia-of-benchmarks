package steiner_tree_subset_dp

MAX_N :: 8
MAX_M :: 14
MAX_K :: 5
MAX_INPUT :: 50
MAX_MASKS :: 1 << MAX_K
INF :: i64(1_000_000_000_000_000_000)

@(export)
steiner_tree_subset_dp :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > c.size_t(MAX_INPUT) do return -1
	n0, m0, k0 := input[0], input[1], input[2]
	if n0 < 1 || n0 > MAX_N || m0 < 0 || m0 > MAX_M || k0 < 1 || k0 > MAX_K || k0 > n0 do return -1
	n, m, k := int(n0), int(m0), int(k0)
	if m > n * (n - 1) / 2 || int(length) != 3 + k + 3*m do return -1
	terminal_seen: [MAX_N]bool
	terminals: [MAX_K]int
	for i := 0; i < k; i += 1 {
		raw := input[3+i]
		if raw < 0 || raw >= n0 do return -1
		vertex := int(raw)
		if terminal_seen[vertex] do return -1
		terminal_seen[vertex] = true
		terminals[i] = vertex
	}
	present: [MAX_N*MAX_N]bool
	weights: [MAX_N*MAX_N]i64
	for i := 0; i < m; i += 1 {
		u0, v0, w := input[3+k+3*i], input[4+k+3*i], input[5+k+3*i]
		if u0 < 0 || u0 >= v0 || v0 >= n0 || w < 0 || w > 1000 do return -1
		u, v := int(u0), int(v0)
		edge := u*MAX_N+v
		if present[edge] do return -1
		present[edge] = true
		present[v*MAX_N+u] = true
		weights[edge] = w
		weights[v*MAX_N+u] = w
	}
	dp: [MAX_MASKS*MAX_N]i64
	for i := 0; i < MAX_MASKS*MAX_N; i += 1 do dp[i] = INF
	for bit := 0; bit < k; bit += 1 do dp[(1<<bit)*MAX_N+terminals[bit]] = 0
	masks := 1 << k
	for mask := 1; mask < masks; mask += 1 {
		if mask & (mask-1) != 0 {
			sub := (mask-1)&mask
			for sub > 0 {
				other := mask ^ sub
				if sub < other {
					for v := 0; v < n; v += 1 {
						left, right := dp[sub*MAX_N+v], dp[other*MAX_N+v]
						if left < INF && right < INF && left+right < dp[mask*MAX_N+v] do dp[mask*MAX_N+v] = left+right
					}
				}
				sub = (sub-1)&mask
			}
		}
		used: [MAX_N]bool
		for step := 0; step < n; step += 1 {
			chosen := -1
			for v := 0; v < n; v += 1 {
				if !used[v] && (chosen < 0 || dp[mask*MAX_N+v] < dp[mask*MAX_N+chosen]) do chosen = v
			}
			if chosen < 0 || dp[mask*MAX_N+chosen] >= INF do break
			used[chosen] = true
			for v := 0; v < n; v += 1 {
				edge := chosen*MAX_N+v
				if present[edge] && !used[v] {
					candidate := dp[mask*MAX_N+chosen]+weights[edge]
					if candidate < dp[mask*MAX_N+v] do dp[mask*MAX_N+v] = candidate
				}
			}
		}
	}
	answer := INF
	for v := 0; v < n; v += 1 do if dp[(masks-1)*MAX_N+v] < answer do answer = dp[(masks-1)*MAX_N+v]
	if answer >= INF do return -2
	return answer
}
