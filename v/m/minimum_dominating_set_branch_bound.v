module minimum_dominating_set_branch_bound

const max_n = 12
const max_input = 135

fn mds_popcount(bits_value u64) int {
	mut bits := bits_value
	mut count := 0
	for bits != 0 { bits &= bits - u64(1); count++ }
	return count
}

fn mds_search(closed [max_n]u64, n int, full u64, covered u64, chosen int, best_value int) int {
	if chosen >= best_value { return best_value }
	if covered == full { return chosen }
	uncovered := full & ~covered
	uncovered_count := mds_popcount(uncovered)
	mut maximum_gain := 0
	for v in 0 .. n { maximum_gain = max(maximum_gain, mds_popcount(closed[v] & uncovered)) }
	lower_bound := (uncovered_count + maximum_gain - 1) / maximum_gain
	if chosen + lower_bound >= best_value { return best_value }
	mut branch := 0
	mut branch_degree := max_n + 1
	for v in 0 .. n {
		if (uncovered & (u64(1) << v)) != 0 {
			degree := mds_popcount(closed[v])
			if degree < branch_degree { branch = v; branch_degree = degree }
		}
	}
	mut candidates := [max_n]int{}
	mut gains := [max_n]int{}
	mut count := 0
	for v in 0 .. n {
		if (closed[branch] & (u64(1) << v)) == 0 { continue }
		gain := mds_popcount(closed[v] & uncovered)
		mut pos := count
		for pos > 0 && (gain > gains[pos - 1] || (gain == gains[pos - 1] && v < candidates[pos - 1])) {
			gains[pos] = gains[pos - 1]
			candidates[pos] = candidates[pos - 1]
			pos--
		}
		gains[pos] = gain; candidates[pos] = v; count++
	}
	mut result := best_value
	for i in 0 .. count {
		v := candidates[i]
		result = mds_search(closed, n, full, covered | closed[v], chosen + 1, result)
	}
	return result
}

@[export: 'minimum_dominating_set_branch_bound']
pub fn minimum_dominating_set_branch_bound(packed &i64, length usize) i64 {
	unsafe {
		if packed == nil || length < 2 || length > max_input { return -1 }
		n64, m64 := packed[0], packed[1]
		if n64 < 1 || n64 > max_n { return -1 }
		n := int(n64)
		max_edges := n64 * (n64 - 1) / 2
		if m64 < 0 || m64 > max_edges || length != usize(2 + 2 * m64) { return -1 }
		mut adjacency := [max_n]u64{}
		for e in 0 .. int(m64) {
			u64, v64 := packed[2 + 2 * e], packed[3 + 2 * e]
			if u64 < 0 || v64 < 0 || u64 >= n64 || v64 >= n64 || u64 == v64 { return -1 }
			u, v := int(u64), int(v64)
			bit := u64(1) << v
			if adjacency[u] & bit != 0 { return -1 }
			adjacency[u] |= bit; adjacency[v] |= u64(1) << u
		}
		mut closed := [max_n]u64{}
		for v in 0 .. n { closed[v] = adjacency[v] | (u64(1) << v) }
		full := (u64(1) << n) - u64(1)
		mut covered := u64(0)
		mut greedy := 0
		for covered != full {
			mut vertex := 0
			mut best_gain := -1
			for v in 0 .. n {
				gain := mds_popcount(closed[v] & ~covered)
				if gain > best_gain { vertex = v; best_gain = gain }
			}
			covered |= closed[vertex]; greedy++
		}
		return i64(mds_search(closed, n, full, u64(0), 0, greedy))
	}
}
