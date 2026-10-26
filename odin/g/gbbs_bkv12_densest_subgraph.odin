// Clean-room bounded GBBS BKV12 profile; see package LICENSE.txt.
package gbbs_bkv12_densest_subgraph

import "core:c"

N :: 16
M :: 64
MAX_INPUT :: 132
INVALID :: -1e300

@(export)
gbbs_bkv12_densest_subgraph :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length < 2 || length > MAX_INPUT do return INVALID
	n64, m64 := input[0], input[1]
	if n64 < 1 || n64 > N || m64 < 0 || m64 > M || length != c.size_t(2 + 2*m64) do return INVALID
	n, m := int(n64), int(m64)
	adjacent: [N * N]bool = {}
	degree: [N]int = {}
	edge_u, edge_v: [M]int = {}, {}
	for edge := 0; edge < m; edge += 1 {
		u64, v64 := input[2+2*edge], input[3+2*edge]
		if u64 < 0 || u64 >= v64 || v64 >= n64 do return INVALID
		u, v := int(u64), int(v64)
		if adjacent[u*N+v] do return INVALID
		adjacent[u*N+v], adjacent[v*N+u] = true, true
		degree[u] += 1; degree[v] += 1; edge_u[edge], edge_v[edge] = u, v
	}
	alive: [N]bool
	for vertex := 0; vertex < n; vertex += 1 do alive[vertex] = true
	remaining := n
	best := 0.0
	for remaining > 0 {
		total := 0
		for vertex := 0; vertex < n; vertex += 1 { if alive[vertex] do total += degree[vertex] }
		density := f64(total) / f64(remaining)
		if density > best do best = density
		removed: [N]bool
		count := 0
		for vertex := 0; vertex < n; vertex += 1 {
			if alive[vertex] && 1000*degree[vertex]*remaining <= 1001*total {
				removed[vertex] = true; count += 1
			}
		}
		if count == 0 do return INVALID
		for vertex := 0; vertex < n; vertex += 1 { if removed[vertex] do alive[vertex] = false }
		remaining -= count
		for edge := 0; edge < m; edge += 1 {
			u, v := edge_u[edge], edge_v[edge]
			if removed[u] && alive[v] do degree[v] -= 1
			if removed[v] && alive[u] do degree[u] -= 1
		}
	}
	return best
}
