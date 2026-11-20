package minimum_bounded_s_t_flow

import "core:c"

MAX_N :: 6
MAX_M :: 8
MAX_INPUT :: 37
NODE_CAP :: 8

feasible :: proc(input: [^]i64, n, m, source, sink: int, flow_cap: i64) -> bool {
	var residual: [NODE_CAP * NODE_CAP]i64
	var balance: [MAX_N]i64
	for index := 0; index < m; index += 1 {
		offset := 4 + 4 * index
		u, v := int(input[offset]), int(input[offset+1])
		lower, upper := input[offset+2], input[offset+3]
		residual[u*NODE_CAP+v] += upper - lower
		balance[u] -= lower
		balance[v] += lower
	}
	residual[sink*NODE_CAP+source] += flow_cap

	super_source, super_sink := n, n+1
	node_count := n+2
	demand: i64 = 0
	for vertex := 0; vertex < n; vertex += 1 {
		if balance[vertex] > 0 {
			residual[super_source*NODE_CAP+vertex] += balance[vertex]
			demand += balance[vertex]
		} else if balance[vertex] < 0 {
			residual[vertex*NODE_CAP+super_sink] -= balance[vertex]
		}
	}

	flow: i64 = 0
	for flow < demand {
		var parent: [NODE_CAP]int
		for vertex := 0; vertex < node_count; vertex += 1 { parent[vertex] = -1 }
		var queue: [NODE_CAP]int
		head, tail := 0, 0
		parent[super_source] = super_source
		queue[tail] = super_source
		tail += 1
		for head < tail && parent[super_sink] < 0 {
			u := queue[head]
			head += 1
			for v := 0; v < node_count; v += 1 {
				if residual[u*NODE_CAP+v] > 0 && parent[v] < 0 {
					parent[v] = u
					queue[tail] = v
					tail += 1
					if v == super_sink { break }
				}
			}
		}
		if parent[super_sink] < 0 { break }
		amount := demand - flow
		vertex := super_sink
		for vertex != super_source {
			u := parent[vertex]
			if residual[u*NODE_CAP+vertex] < amount { amount = residual[u*NODE_CAP+vertex] }
			vertex = u
		}
		vertex = super_sink
		for vertex != super_source {
			u := parent[vertex]
			residual[u*NODE_CAP+vertex] -= amount
			residual[vertex*NODE_CAP+u] += amount
			vertex = u
		}
		flow += amount
	}
	return flow == demand
}

@(export)
minimum_bounded_s_t_flow :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	unsafe {
		if input == nil || length < 4 || length > c.size_t(MAX_INPUT) do return -1
		n_arg, m_arg := input[0], input[1]
		source_arg, sink_arg := input[2], input[3]
		if n_arg < 2 || n_arg > MAX_N || m_arg < 0 || m_arg > MAX_M do return -1
		if source_arg < 0 || source_arg >= n_arg || sink_arg < 0 || sink_arg >= n_arg ||
			source_arg == sink_arg do return -1
		n, m := int(n_arg), int(m_arg)
		source, sink := int(source_arg), int(sink_arg)
		if length != c.size_t(4 + 4*m) do return -1

		upper_bound: i64 = 0
		for index := 0; index < m; index += 1 {
			offset := 4 + 4*index
			u_arg, v_arg := input[offset], input[offset+1]
			lower, upper := input[offset+2], input[offset+3]
			if u_arg < 0 || u_arg >= n_arg || v_arg < 0 || v_arg >= n_arg ||
				lower < 0 || upper < lower || upper > 2 do return -1
			if int(u_arg) == source && int(v_arg) != source { upper_bound += upper }
		}

		low: i64 = 0
		high := upper_bound + 1
		for low < high {
			middle := low + (high-low)/2
			if feasible(input, n, m, source, sink, middle) { high = middle }
			else { low = middle + 1 }
		}
		if low > upper_bound do return -2
		return low
	}
}
