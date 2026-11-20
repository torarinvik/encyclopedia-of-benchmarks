package minimum_dominating_set_branch_bound

import "core:c"

MAX_N :: 12
MAX_INPUT :: 135

popcount :: proc "contextless" (bits_input: u64) -> int {
	bits := bits_input
	count := 0
	for bits != 0 { bits &= bits-1; count += 1 }
	return count
}

search_mds :: proc "contextless" (closed: [MAX_N]u64, n: int, full, covered: u64, chosen, best_input: int) -> int {
	if chosen >= best_input do return best_input
	if covered == full do return chosen
	uncovered := full & ~covered
	uncovered_count := popcount(uncovered)
	maximum_gain := 0
	for v := 0; v < n; v += 1 { maximum_gain = max(maximum_gain, popcount(closed[v] & uncovered)) }
	lower_bound := (uncovered_count + maximum_gain - 1) / maximum_gain
	if chosen + lower_bound >= best_input do return best_input

	branch := 0
	branch_degree := MAX_N + 1
	for v := 0; v < n; v += 1 {
		if (uncovered & (u64(1)<<v)) != 0 {
			degree := popcount(closed[v])
			if degree < branch_degree { branch = v; branch_degree = degree }
		}
	}
	var candidates: [MAX_N]int
	var gains: [MAX_N]int
	count := 0
	for v := 0; v < n; v += 1 {
		if (closed[branch] & (u64(1)<<v)) == 0 do continue
		gain := popcount(closed[v] & uncovered)
		pos := count
		for pos > 0 && (gain > gains[pos-1] || (gain == gains[pos-1] && v < candidates[pos-1])) {
			gains[pos] = gains[pos-1]
			candidates[pos] = candidates[pos-1]
			pos -= 1
		}
		gains[pos] = gain; candidates[pos] = v; count += 1
	}
	result := best_input
	for i := 0; i < count; i += 1 {
		v := candidates[i]
		result = search_mds(closed, n, full, covered | closed[v], chosen+1, result)
	}
	return result
}

@(export)
minimum_dominating_set_branch_bound :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed == nil || length < 2 || length > c.size_t(MAX_INPUT) do return -1
	n64, m64 := packed[0], packed[1]
	if n64 < 1 || n64 > MAX_N do return -1
	n := int(n64)
	max_edges := n64*(n64-1)/2
	if m64 < 0 || m64 > max_edges || length != c.size_t(2+2*m64) do return -1
	var adjacency: [MAX_N]u64
	for e := 0; e < int(m64); e += 1 {
		u64, v64 := packed[2+2*e], packed[3+2*e]
		if u64 < 0 || v64 < 0 || u64 >= n64 || v64 >= n64 || u64 == v64 do return -1
		u, v := int(u64), int(v64)
		bit := u64(1)<<v
		if adjacency[u]&bit != 0 do return -1
		adjacency[u] |= bit; adjacency[v] |= u64(1)<<u
	}
	var closed: [MAX_N]u64
	for v := 0; v < n; v += 1 { closed[v] = adjacency[v] | (u64(1)<<v) }
	full := (u64(1)<<n)-1
	covered: u64 = 0
	greedy := 0
	for covered != full {
		vertex := 0; best_gain := -1
		for v := 0; v < n; v += 1 {
			gain := popcount(closed[v] & ~covered)
			if gain > best_gain { vertex = v; best_gain = gain }
		}
		covered |= closed[vertex]; greedy += 1
	}
	return i64(search_mds(closed, n, full, 0, 0, greedy))
}
