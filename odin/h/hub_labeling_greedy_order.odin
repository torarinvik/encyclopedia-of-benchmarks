package hub_labeling_greedy_order

import "core:c"

Max_N :: 8
Max_M :: 28
Max_Out :: 81

ancestor :: proc(parent: [Max_N][Max_N]int, source, a, target: int) -> bool {
	v := target
	for v >= 0 {
		if v == a { return true }
		if v == source { break }
		v = parent[source][v]
	}
	return false
}
put_i64 :: proc(out: [^]u8, pos: int, value: i64) {
	bits := u64(value)
	for b in 0..<8 { out[pos+b] = u8((bits >> (8*b)) & 255) }
}

@(export)
hub_labeling_greedy_order :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 58 do return -1
	n0 := input[0]; m0 := input[1]
	if n0 < 1 || n0 > Max_N || m0 < 0 || m0 > n0*(n0-1)/2 || length != c.size_t(2+2*m0) do return -1
	n := int(n0); m := int(m0)
	adj: [Max_N][Max_N]bool
	prev_u: i64 = -1; prev_v: i64 = -1
	for e in 0..<m {
		u := input[2+2*e]; v := input[3+2*e]
		if u < 0 || v <= u || v >= n0 || (e > 0 && (u < prev_u || (u == prev_u && v <= prev_v))) do return -1
		adj[int(u)][int(v)] = true; adj[int(v)][int(u)] = true; prev_u = u; prev_v = v
	}
	parent: [Max_N][Max_N]int; depth: [Max_N][Max_N]int; ways: [Max_N][Max_N]int
	for s in 0..<n {
		for v in 0..<n { parent[s][v] = -1; depth[s][v] = -1; ways[s][v] = 0 }
		queue: [Max_N]int; head := 0; tail := 0
		queue[tail] = s; tail += 1; depth[s][s] = 0; ways[s][s] = 1
		for head < tail {
			u := queue[head]; head += 1
			for v in 0..<n {
				if adj[u][v] {
					if depth[s][v] < 0 { depth[s][v] = depth[s][u]+1; parent[s][v] = u; ways[s][v] = ways[s][u]; queue[tail] = v; tail += 1 }
					else if depth[s][v] == depth[s][u]+1 { ways[s][v] += ways[s][u]; if ways[s][v] > 2 { ways[s][v] = 2 } }
				}
			}
		}
		for v in 0..<n { if depth[s][v] < 0 || ways[s][v] != 1 do return -1 }
	}
	active: [Max_N][Max_N]bool
	for s in 0..<n { for t in 0..<n { active[s][t] = true } }
	order: [Max_N]int; rank: [Max_N]int
	for turn in 0..<n {
		counts: [Max_N]int
		for s in 0..<n { for t in 0..<n { if active[s][t] {
			v := t
			for v >= 0 { counts[v] += 1; if v == s { break }; v = parent[s][v] }
		} } }
		best := 0
		for v in 1..<n { if counts[v] > counts[best] { best = v } }
		order[turn] = best; rank[best] = turn
		for s in 0..<n { for t in 0..<n { if active[s][t] && ancestor(parent,s,best,t) { active[s][t] = false } } }
	}
	has: [Max_N][Max_N]bool; label_dist: [Max_N][Max_N]int
	for u in 0..<n { for v in u..<n {
		path: [Max_N]int; path_len := 0; x := v
		for x >= 0 { path[path_len] = x; path_len += 1; if x == u { break }; x = parent[u][x] }
		if x < 0 do return -1
		hub := path[0]
		for i in 1..<path_len { if rank[path[i]] < rank[hub] { hub = path[i] } }
		has[u][hub] = true; has[v][hub] = true; label_dist[u][hub] = depth[u][hub]; label_dist[v][hub] = depth[v][hub]
	} }
	staged: [Max_Out]i64; used := 0
	staged[used] = i64(n); used += 1
	for i in 0..<n { staged[used] = i64(order[i]); used += 1 }
	for v in 0..<n {
		count := 0; for h in 0..<n { if has[v][h] { count += 1 } }
		staged[used] = i64(count); used += 1
		for h in 0..<n { if has[v][h] { staged[used] = i64(h | (label_dist[v][h] << 8)); used += 1 } }
	}
	required := used*8
	if output == nil || capacity < c.size_t(required) do return -2
	for i in 0..<used { put_i64(output,i*8,staged[i]) }
	return i64(required)
}
