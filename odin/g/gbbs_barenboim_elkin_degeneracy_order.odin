// Clean-room bounded GBBS Barenboim-Elkin degeneracy-order profile.
package gbbs_barenboim_elkin_degeneracy_order

import "core:c"

N :: 20
M :: 190
MAX_INPUT :: 382

store_i64_le :: proc(output: [^]u8, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
gbbs_barenboim_elkin_degeneracy_order :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	n64, m64 := input[0], input[1]
	if n64 < 1 || n64 > N || m64 < 0 || m64 > M do return -1
	n, m := int(n64), int(m64)
	if length != c.size_t(2 + 2*m) do return -1
	adjacent: [N][N]bool = {}
	initial_degree: [N]int = {}
	for edge := 0; edge < m; edge += 1 {
		u64, v64 := input[2+2*edge], input[3+2*edge]
		if u64 < 0 || u64 >= v64 || v64 >= n64 do return -1
		u, v := int(u64), int(v64)
		if adjacent[u][v] do return -1
		adjacent[u][v], adjacent[v][u] = true, true
		initial_degree[u] += 1; initial_degree[v] += 1
	}
	if output == nil || capacity < c.size_t(8*n) do return -2
	degree: [N]int = initial_degree
	alive: [N]bool = {}
	for v := 0; v < n; v += 1 do alive[v] = true
	remaining := n
	best_num, best_den := 0, 1
	for remaining > 0 {
		total := 0
		for v := 0; v < n; v += 1 { if alive[v] do total += degree[v] }
		if total*best_den > best_num*remaining { best_num, best_den = total, remaining }
		removed: [N]bool = {}
		count := 0
		for v := 0; v < n; v += 1 {
			if alive[v] && 10*degree[v]*remaining <= 11*total { removed[v] = true; count += 1 }
		}
		if count == 0 do return -1
		for v := 0; v < n; v += 1 { if removed[v] do alive[v] = false }
		remaining -= count
		for v := 0; v < n; v += 1 {
			if alive[v] {
				decrement := 0
				for u := 0; u < n; u += 1 { if removed[u] && adjacent[v][u] do decrement += 1 }
				degree[v] -= decrement
			}
		}
	}
	cutoff := (best_num + 10*best_den - 1) / (10*best_den)
	if cutoff < 1 do cutoff = 1
	degree = initial_degree
	alive = {}
	for v := 0; v < n; v += 1 do alive[v] = true
	order: [N]int = {}
	used := 0
	for used < n {
		shell: [N]int = {}
		count := 0
		for v := 0; v < n; v += 1 { if alive[v] && degree[v] < cutoff { shell[count] = v; count += 1 } }
		if count == 0 { for v := 0; v < n; v += 1 { if alive[v] { shell[count] = v; count += 1; break } } }
		for i := 0; i < count; i += 1 { alive[shell[i]] = false; order[used] = shell[i]; used += 1 }
		for v := 0; v < n; v += 1 {
			if alive[v] {
				decrement := 0
				for i := 0; i < count; i += 1 { if adjacent[v][shell[i]] do decrement += 1 }
				degree[v] -= decrement
			}
		}
	}
	rank: [N]i64 = {}
	for i := 0; i < n; i += 1 do rank[order[i]] = i64(i)
	for v := 0; v < n; v += 1 do store_i64_le(output + 8*v, rank[v])
	return i64(8*n)
}
