package lower_bound_circulation_feasibility

import "core:c"

MAX_N :: 6
MAX_M :: 8
MAX_INPUT :: 35
NODE_CAP :: 8

@(export)
lower_bound_circulation_feasibility :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT) do return -1
	n_arg, m_arg := input[0], input[1]
	if n_arg < 1 || n_arg > MAX_N || m_arg < 0 || m_arg > MAX_M do return -1
	n, m := int(n_arg), int(m_arg)
	if length != c.size_t(2 + 4 * m) do return -1

	var residual: [NODE_CAP * NODE_CAP]i64
	var balance: [MAX_N]i64
	for index := 0; index < m; index += 1 {
		offset := 2 + 4 * index
		u_arg, v_arg := input[offset], input[offset+1]
		lower, upper := input[offset+2], input[offset+3]
		if u_arg < 0 || u_arg >= n_arg || v_arg < 0 || v_arg >= n_arg ||
			lower < 0 || upper < lower || upper > 2 do return -1
		u, v := int(u_arg), int(v_arg)
		residual[u*NODE_CAP+v] += upper - lower
		balance[u] -= lower
		balance[v] += lower
	}

	source, sink := n, n+1
	node_count := n + 2
	demand: i64 = 0
	for vertex := 0; vertex < n; vertex += 1 {
		if balance[vertex] > 0 {
			residual[source*NODE_CAP+vertex] += balance[vertex]
			demand += balance[vertex]
		} else if balance[vertex] < 0 {
			residual[vertex*NODE_CAP+sink] -= balance[vertex]
		}
	}

	flow: i64 = 0
	for flow < demand {
		var parent: [NODE_CAP]int
		for vertex := 0; vertex < node_count; vertex += 1 { parent[vertex] = -1 }
		var queue: [NODE_CAP]int
		head, tail := 0, 0
		parent[source] = source
		queue[tail] = source
		tail += 1
		for head < tail && parent[sink] < 0 {
			u := queue[head]
			head += 1
			for v := 0; v < node_count; v += 1 {
				if residual[u*NODE_CAP+v] > 0 && parent[v] < 0 {
					parent[v] = u
					queue[tail] = v
					tail += 1
					if v == sink { break }
				}
			}
		}
		if parent[sink] < 0 { break }
		amount := demand - flow
		vertex := sink
		for vertex != source {
			u := parent[vertex]
			if residual[u*NODE_CAP+vertex] < amount { amount = residual[u*NODE_CAP+vertex] }
			vertex = u
		}
		vertex = sink
		for vertex != source {
			u := parent[vertex]
			residual[u*NODE_CAP+vertex] -= amount
			residual[vertex*NODE_CAP+u] += amount
			vertex = u
		}
		flow += amount
	}
	if flow == demand { return 1 }
	return 0
}
