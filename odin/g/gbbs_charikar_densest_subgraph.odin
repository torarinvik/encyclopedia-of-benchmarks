// Clean-room bounded GBBS Charikar profile; see package LICENSE.txt.
package gbbs_charikar_densest_subgraph

import "core:c"
import "core:math"

MAX_N :: 16
MAX_M :: 64
INVALID_RESULT :: -1e300

@(export)
gbbs_charikar_densest_subgraph :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length < 2 || length > 130 do return INVALID_RESULT
	n64 := input[0]
	m64 := input[1]
	if n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M || length != c.size_t(2 + 2 * m64) do return INVALID_RESULT
	n := int(n64)
	m := int(m64)
	adjacent: [MAX_N * MAX_N]bool
	degree: [MAX_N]int
	for edge := 0; edge < m; edge += 1 {
		u64 := input[2 + 2 * edge]
		v64 := input[3 + 2 * edge]
		if u64 < 0 || u64 >= v64 || v64 >= n64 do return INVALID_RESULT
		u := int(u64)
		v := int(v64)
		if adjacent[u * MAX_N + v] do return INVALID_RESULT
		adjacent[u * MAX_N + v] = true
		adjacent[v * MAX_N + u] = true
		degree[u] += 1
		degree[v] += 1
	}
	alive: [MAX_N]bool
	order: [MAX_N]int
	position: [MAX_N]int
	for v := 0; v < n; v += 1 { alive[v] = true }
	used := 0
	for used < n {
		level := MAX_M
		for v := 0; v < n; v += 1 { if alive[v] && degree[v] < level { level = degree[v] } }
		for {
			shell: [MAX_N]int
			count := 0
			for v := 0; v < n; v += 1 { if alive[v] && degree[v] == level { shell[count] = v; count += 1 } }
			if count == 0 do break
			for i := 0; i < count; i += 1 { alive[shell[i]] = false; order[used] = shell[i]; used += 1 }
			for v := 0; v < n; v += 1 { if alive[v] {
				removed := 0
				for i := 0; i < count; i += 1 { if adjacent[v * MAX_N + shell[i]] do removed += 1 }
				next := degree[v] - removed
				degree[v] = if next < level then level else next
			} }
		}
	}
	for i := 0; i < n; i += 1 { position[order[i]] = i }
	best := 0.0
	for start := 0; start < n; start += 1 {
		edges := 0
		for u := 0; u < n; u += 1 { if position[u] >= start { for v := u + 1; v < n; v += 1 {
			if position[v] >= start && adjacent[u * MAX_N + v] do edges += 1
		} } }
		score := 2.0 * f64(edges) / f64(n - start)
		if score > best { best = score }
	}
	if !math.is_finite(best) do return INVALID_RESULT
	return best
}
