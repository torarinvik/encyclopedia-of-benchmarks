// Clean-room Goldberg exact maximum-density profile.
package goldberg_maximum_density_subgraph

import "core:c"

MAX_N :: 8
MAX_M :: 28
MAX_NETWORK :: 10

@(export)
goldberg_maximum_density_subgraph :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 59 do return -1
	n64 := input[0]
	m64 := input[1]
	if n64 < 2 || n64 > MAX_N || m64 < 0 || m64 > MAX_M || length != c.size_t(2 + 2 * m64) do return -1
	n := int(n64)
	m := int(m64)
	adjacent: [MAX_N * MAX_N]bool
	degree: [MAX_N]i64
	edge_u, edge_v: [MAX_M]int
	for edge := 0; edge < m; edge += 1 {
		u64 := input[2 + 2 * edge]
		v64 := input[3 + 2 * edge]
		if u64 < 0 || u64 >= v64 || v64 >= n64 do return -1
		u := int(u64)
		v := int(v64)
		if adjacent[u * MAX_N + v] do return -1
		adjacent[u * MAX_N + v] = true
		adjacent[v * MAX_N + u] = true
		edge_u[edge] = u
		edge_v[edge] = v
		degree[u] += 1
		degree[v] += 1
	}
	if m == 0 do return 1
	low: i64 = 0
	high: i64 = m64
	denominator: i64 = 1
	best: [MAX_N]bool
	for (high - low) * n64 * (n64 - 1) >= denominator {
		low2 := 2 * low
		high2 := 2 * high
		midpoint := low + high
		next_denominator := 2 * denominator
		source := n
		sink := n + 1
		network_size := n + 2
		residual: [MAX_NETWORK * MAX_NETWORK]i64
		for v := 0; v < n; v += 1 {
			source_capacity := m64 * next_denominator
			residual[source * MAX_NETWORK + v] = source_capacity
			residual[v * MAX_NETWORK + sink] = source_capacity + 2 * midpoint - next_denominator * degree[v]
		}
		for edge := 0; edge < m; edge += 1 {
			u := edge_u[edge]
			v := edge_v[edge]
			residual[u * MAX_NETWORK + v] += next_denominator
			residual[v * MAX_NETWORK + u] += next_denominator
		}
		for {
			parent: [MAX_NETWORK]int
			for v := 0; v < network_size; v += 1 { parent[v] = -1 }
			queue: [MAX_NETWORK]int
			head := 0
			tail := 0
			parent[source] = source
			queue[tail] = source
			tail += 1
			for head < tail && parent[sink] == -1 {
				here := queue[head]
				head += 1
				for there := 0; there < network_size; there += 1 {
					if parent[there] == -1 && residual[here * MAX_NETWORK + there] > 0 {
						parent[there] = here
						queue[tail] = there
						tail += 1
						if there == sink do break
					}
				}
			}
			if parent[sink] == -1 do break
			amount: i64 = 1 << 60
			for vertex := sink; vertex != source; vertex = parent[vertex] {
				previous := parent[vertex]
				if residual[previous * MAX_NETWORK + vertex] < amount { amount = residual[previous * MAX_NETWORK + vertex] }
			}
			for vertex := sink; vertex != source; vertex = parent[vertex] {
				previous := parent[vertex]
				residual[previous * MAX_NETWORK + vertex] -= amount
				residual[vertex * MAX_NETWORK + previous] += amount
			}
		}
		reachable: [MAX_NETWORK]bool
		queue: [MAX_NETWORK]int
		head := 0
		tail := 0
		reachable[source] = true
		queue[tail] = source
		tail += 1
		for head < tail {
			here := queue[head]
			head += 1
			for there := 0; there < network_size; there += 1 {
				if !reachable[there] && residual[here * MAX_NETWORK + there] > 0 {
					reachable[there] = true
					queue[tail] = there
					tail += 1
				}
			}
		}
		selected: [MAX_N]bool
		any := false
		for v := 0; v < n; v += 1 { selected[v] = reachable[v]; any = any || selected[v] }
		if any { for v := 0; v < n; v += 1 { best[v] = selected[v] }; low = midpoint; high = high2 } else { low = low2; high = midpoint }
		denominator = next_denominator
	}
	vertex_count: i64 = 0
	edge_count: i64 = 0
	for v := 0; v < n; v += 1 { if best[v] { vertex_count += 1 } }
	if vertex_count == 0 do return 1
	for edge := 0; edge < m; edge += 1 { if best[edge_u[edge]] && best[edge_v[edge]] { edge_count += 1 } }
	a := edge_count
	b := vertex_count
	for b != 0 { r := a % b; a = b; b = r }
	return (edge_count / a) * (n64 + 1) + vertex_count / a
}
