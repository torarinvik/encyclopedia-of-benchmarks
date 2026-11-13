module isap_maxflow

const n_max = 8
const m_max = 24
const input_max = 77

fn isap_dfs(u int, sink int, amount i64, n int, mut residual [64]i64,
    distance [8]i64, mut gap [9]i64, mut current [8]int, mut stopped bool) i64 {
	if u == sink { return amount }
	for current[u] < n {
		v := current[u]
		edge := u * 8 + v
		if residual[edge] > 0 && distance[u] == distance[v] + 1 {
			limit := amount
			if residual[edge] < limit { limit = residual[edge] }
			sent := isap_dfs(v, sink, limit, n, mut residual, distance, mut gap, mut current, mut stopped)
			if sent > 0 { residual[edge] -= sent; residual[v * 8 + u] += sent; return sent }
			if stopped { return 0 }
		}
		current[u]++
	}
	old := distance[u]
	mut best := i64(n)
	for v in 0 .. n {
		if residual[u * 8 + v] > 0 && distance[v] < best { best = distance[v] }
	}
	replacement := best + 1
	if replacement > i64(n) { replacement = i64(n) }
	gap[int(old)]--
	distance[u] = replacement
	gap[int(replacement)]++
	current[u] = 0
	if old < i64(n) && gap[int(old)] == 0 { stopped = true }
	return 0
}

@[export: 'isap_maxflow']
pub fn isap_maxflow(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 4 || length > input_max { return -1 }
	unsafe {
		nv, mv, sv, tv := input[0], input[1], input[2], input[3]
		if nv < 2 || nv > n_max || mv < 0 || mv > m_max || sv < 0 || sv >= nv || tv < 0 || tv >= nv || sv == tv { return -1 }
		n, m, source, sink := int(nv), int(mv), int(sv), int(tv)
		if length != usize(4 + 3 * m) { return -1 }
		mut residual := [64]i64{}
		for e in 0 .. m {
			u, v, capacity := input[4 + 3 * e], input[5 + 3 * e], input[6 + 3 * e]
			if u < 0 || u >= nv || v < 0 || v >= nv || u == v || capacity < 0 || capacity > 100 { return -1 }
			residual[int(u) * 8 + int(v)] += capacity
		}
		mut distance := [8]i64{}
		mut gap := [9]i64{}
		mut current := [8]int{}
		mut queue := [8]int{}
		for v in 0 .. n { distance[v] = i64(n) }
		distance[sink] = 0
		mut head, mut tail := 0, 1
		queue[0] = sink
		for head < tail {
			v := queue[head]
			head++
			for p in 0 .. n {
				if distance[p] == i64(n) && residual[p * 8 + v] > 0 {
					distance[p] = distance[v] + 1
					queue[tail] = p
					tail++
				}
			}
		}
		if distance[source] >= i64(n) { return 0 }
		for v in 0 .. n { gap[int(distance[v])]++ }
		mut stopped := false
		mut flow := i64(0)
		for distance[source] < i64(n) && !stopped {
			flow += isap_dfs(source, sink, 2400, n, mut residual, distance, mut gap, mut current, mut stopped)
		}
		return flow
	}
}
