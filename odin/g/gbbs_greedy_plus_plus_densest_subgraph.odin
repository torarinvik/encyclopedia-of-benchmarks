// Clean-room bounded GBBS GreedyPlusPlus profile; see package LICENSE.txt.
package gbbs_greedy_plus_plus_densest_subgraph

import "core:c"

N :: 16
M :: 64
MAX_INPUT :: 132
INVALID :: -1e300

@(export)
gbbs_greedy_plus_plus_densest_subgraph :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length < 2 || length > MAX_INPUT do return INVALID
	n64, m64 := input[0], input[1]
	if n64 < 10 || n64 > N || m64 < 0 || m64 > M || length != c.size_t(2 + 2*m64) do return INVALID
	n, m := int(n64), int(m64)
	adjacent: [N * N]bool = {}
	load: [N]int64 = {}
	for edge := 0; edge < m; edge += 1 {
		u64, v64 := input[2+2*edge], input[3+2*edge]
		if u64 < 0 || u64 >= v64 || v64 >= n64 do return INVALID
		u, v := int(u64), int(v64)
		if adjacent[u*N+v] do return INVALID
		adjacent[u*N+v], adjacent[v*N+u] = true, true
		load[u] += 1; load[v] += 1
	}
	best := 0.0
	for round := 0; round < 20; round += 1 {
		degree := load
		alive: [N]bool
		order, position: [N]int = {}, {}
		for vertex := 0; vertex < n; vertex += 1 do alive[vertex] = true
		used := 0
		for used < n {
			level := i64(0x7fffffffffffffff)
			for vertex := 0; vertex < n; vertex += 1 { if alive[vertex] && degree[vertex] < level do level = degree[vertex] }
			shell: [N]int
			count := 0
			for vertex := 0; vertex < n; vertex += 1 { if alive[vertex] && degree[vertex] == level { shell[count] = vertex; count += 1 } }
			for i := 0; i < count; i += 1 { alive[shell[i]] = false; order[used] = shell[i]; used += 1 }
			for vertex := 0; vertex < n; vertex += 1 { if alive[vertex] {
				removed := 0
				for i := 0; i < count; i += 1 { if adjacent[vertex*N+shell[i]] do removed += 1 }
				next := degree[vertex] - i64(removed)
				degree[vertex] = if next < level then level else next
			} }
		}
		for i := 0; i < n; i += 1 do position[order[i]] = i
		density_above: [N]int64
		for vertex := 0; vertex < n; vertex += 1 {
			later := i64(0)
			for other := 0; other < n; other += 1 { if adjacent[vertex*N+other] && position[other] > position[vertex] do later += 1 }
			density_above[position[vertex]] = 2 * later
			load[vertex] += later
		}
		suffix_sum := i64(0)
		index := n
		for index > 0 {
			index -= 1
			suffix_sum += density_above[index]
			score := f64(suffix_sum) / f64(n - index)
			if score > best do best = score
		}
	}
	return best
}
