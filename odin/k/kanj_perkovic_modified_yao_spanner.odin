package kanj_perkovic_modified_yao_spanner

import "core:c"

N :: 16
M :: 42
K :: 14
D :: 84
MAX_VALID :: 312
MAX_PARSEABLE :: 313

@(export)
kanj_perkovic_modified_yao_spanner :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_PARSEABLE do return -1
	n64, m64 := input[0], input[1]
	if n64 < 3 || n64 > N || m64 < n64 - 1 || m64 > M || m64 > 3*n64 - 6 do return -1
	n, m := int(n64), int(m64)
	dcount := 2*m
	if int(length) != 2+n+7*m || length > MAX_VALID do return -1

	var edge_u: [M]int
	var edge_v: [M]int
	var weight: [M]i64
	var adjacent: [N*N]bool
	var expected_degree: [N]int
	var source: [D]int
	var cone: [D]int
	for e := 0; e < m; e += 1 {
		p := 2+5*e
		u64, v64, w := input[p], input[p+1], input[p+2]
		cu64, cv64 := input[p+3], input[p+4]
		if u64 < 0 || u64 >= v64 || v64 >= n64 || w < 1 || w > 1000000000000 ||
			cu64 < 0 || cu64 >= K || cv64 < 0 || cv64 >= K do return -1
		u, v := int(u64), int(v64)
		if e > 0 && (u < edge_u[e-1] || (u == edge_u[e-1] && v <= edge_v[e-1])) do return -1
		edge_u[e], edge_v[e], weight[e] = u, v, w
		adjacent[u*N+v], adjacent[v*N+u] = true, true
		expected_degree[u] += 1; expected_degree[v] += 1
		source[2*e], source[2*e+1] = u, v
		cone[2*e], cone[2*e+1] = int(cu64), int(cv64)
	}
	var rotation: [D]int
	var position: [D]int
	var row_start: [N]int
	var degree: [N]int
	var first: [N*K]int
	var after: [N*K]int
	var seen: [D]bool
	for i := 0; i < N*K; i += 1 { first[i], after[i] = -1, -1 }
	cursor, used := 2+5*m, 0
	for v := 0; v < n; v += 1 {
		d64 := input[cursor]; cursor += 1
		if d64 < 1 || d64 > D || int(d64) != expected_degree[v] do return -1
		d := int(d64); row_start[v], degree[v] = used, d
		previous := -1
		for j := 0; j < d; j += 1 {
			raw := input[cursor]; cursor += 1
			if raw < 0 || raw >= i64(dcount) do return -1
			dart := int(raw); c_id := cone[dart]
			if seen[dart] || source[dart] != v || c_id < previous do return -1
			previous = c_id; seen[dart] = true
			rotation[used], position[dart] = dart, used
			bucket := v*K+c_id
			if first[bucket] < 0 do first[bucket] = used
			after[bucket] = used+1; used += 1
		}
	}
	if cursor != int(length) || used != dcount do return -1
	for d := 0; d < dcount; d += 1 { if !seen[d] do return -1 }
	var reached: [N]bool
	var queue: [N]int
	head, tail := 0, 1
	queue[0], reached[0] = 0, true
	for head < tail {
		u := queue[head]; head += 1
		for v := 0; v < n; v += 1 {
			if adjacent[u*N+v] && !reached[v] { reached[v] = true; queue[tail] = v; tail += 1 }
		}
	}
	if tail != n do return -1
	var next_face: [D]int
	var face_seen: [D]bool
	faces := 0
	for d := 0; d < dcount; d += 1 {
		twin := d^1; dest := source[twin]
		local := position[twin]-row_start[dest]
		next_face[d] = rotation[row_start[dest]+(local+degree[dest]-1)%degree[dest]]
	}
	for d := 0; d < dcount; d += 1 {
		if !face_seen[d] {
			faces += 1; current := d
			for !face_seen[current] { face_seen[current] = true; current = next_face[current] }
			if current != d do return -1
		}
	}
	if n-m+faces != 2 do return -1

	var selected: [D]bool
	for v := 0; v < n; v += 1 {
		for c_id := 0; c_id < K; c_id += 1 {
			bucket := v*K+c_id
			if first[bucket] < 0 do continue
			best := -1
			for p := first[bucket]; p < after[bucket]; p += 1 {
				dart := rotation[p]; e := dart/2
				if best < 0 || weight[e] < weight[best/2] || (weight[e] == weight[best/2] && e < best/2) do best = dart
			}
			selected[best] = true
		}
	}
	for v := 0; v < n; v += 1 {
		occupied := false
		for c_id := 0; c_id < K; c_id += 1 { if first[v*K+c_id] >= 0 do occupied = true }
		if !occupied do continue
		for start := 0; start < K; start += 1 {
			if first[v*K+start] >= 0 || first[v*K+(start+K-1)%K] < 0 do continue
			run := 0
			for run < K && first[v*K+(start+run)%K] < 0 { run += 1 }
			if run == 1 {
				cw_c, ccw_c := (start+K-1)%K, (start+1)%K
				cw, ccw := rotation[after[v*K+cw_c]-1], rotation[first[v*K+ccw_c]]
				if selected[cw] { selected[ccw] = true
				} else if selected[ccw] { selected[cw] = true
				} else {
					a, b := cw/2, ccw/2
					if weight[a] < weight[b] || (weight[a] == weight[b] && a < b) { selected[cw] = true } else { selected[ccw] = true }
				}
			} else {
				cw_left, ccw_left := run/2, (run+1)/2
				for step := 1; step <= K && cw_left > 0; step += 1 {
					c_id := (start-step+K)%K; bucket := v*K+c_id
					if first[bucket] >= 0 {
						for p := after[bucket]-1; p >= first[bucket] && cw_left > 0; p -= 1 {
							dart := rotation[p]
							if !selected[dart] { selected[dart] = true; cw_left -= 1 }
						}
					}
				}
				for step := run; step < run+K && ccw_left > 0; step += 1 {
					c_id := (start+step)%K; bucket := v*K+c_id
					if first[bucket] >= 0 {
						for p := first[bucket]; p < after[bucket] && ccw_left > 0; p += 1 {
							dart := rotation[p]
							if !selected[dart] { selected[dart] = true; ccw_left -= 1 }
						}
					}
				}
			}
		}
	}
	mask: u64 = 0
	for e := 0; e < m; e += 1 { if selected[2*e] && selected[2*e+1] { mask |= u64(1)<<e } }
	return i64(mask)
}
