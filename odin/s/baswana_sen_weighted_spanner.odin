package baswana_sen_weighted_spanner

import "core:c"

MAX_N :: 8
MAX_M :: 28
MAX_INPUT :: 90

bsw_before :: proc(aw, au, av, bw, bu, bv: i64) -> bool {
	return aw < bw || (aw == bw && au < bu) || (aw == bw && au == bu && av < bv)
}

@(export)
baswana_sen_weighted_spanner :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	n64, m64, k := input[0], input[1], input[2]
	if n64 < 2 || n64 > MAX_N || m64 < 0 || m64 > MAX_M || k < 2 || k > 3 do return -1
	n, m, rounds := int(n64), int(m64), int(k-1)
	if length != c.size_t(3+rounds+3*m) do return -1
	var masks: [MAX_N]i64
	for r := 0; r < rounds; r += 1 {
		masks[r] = input[3+r]
		if masks[r] < 0 || masks[r] >= (i64(1) << n) do return -1
	}
	var edge_u, edge_v, edge_w: [MAX_M]i64
	var active, selected: [MAX_M]bool
	offset := 3+rounds
	for e := 0; e < m; e += 1 {
		edge_u[e], edge_v[e], edge_w[e] = input[offset+3*e], input[offset+3*e+1], input[offset+3*e+2]
		if edge_u[e] < 0 || edge_v[e] <= edge_u[e] || edge_v[e] >= n64 || edge_w[e] < 1 || edge_w[e] > 32 do return -1
		for p := 0; p < e; p += 1 do if edge_u[p] == edge_u[e] && edge_v[p] == edge_v[e] do return -1
		active[e] = true
	}
	if output == nil || capacity < c.size_t(m) do return -2
	var cluster, next_cluster: [MAX_N]int
	for v := 0; v < n; v += 1 do cluster[v] = v
	for r := 0; r < rounds; r += 1 {
		var sampled: [MAX_N]bool
		var remove: [MAX_M]bool
		var group_best: [MAX_N*MAX_N]int
		for i := 0; i < MAX_N*MAX_N; i += 1 do group_best[i] = m
		for v := 0; v < n; v += 1 do next_cluster[v] = -1
		for v := 0; v < n; v += 1 {
			center := cluster[v]
			if center >= 0 && ((masks[r] >> center) & 1) != 0 do sampled[center] = true
		}
		for v := 0; v < n; v += 1 do if cluster[v] >= 0 && sampled[cluster[v]] do next_cluster[v] = cluster[v]
		for e := 0; e < m; e += 1 {
			if !active[e] do continue
			u, v := int(edge_u[e]), int(edge_v[e])
			if cluster[v] >= 0 {
				slot := u*MAX_N+cluster[v]; prior := group_best[slot]
				if prior == m || bsw_before(edge_w[e],edge_u[e],edge_v[e],edge_w[prior],edge_u[prior],edge_v[prior]) do group_best[slot] = e
			}
			if cluster[u] >= 0 {
				slot := v*MAX_N+cluster[u]; prior := group_best[slot]
				if prior == m || bsw_before(edge_w[e],edge_u[e],edge_v[e],edge_w[prior],edge_u[prior],edge_v[prior]) do group_best[slot] = e
			}
		}
		for v := 0; v < n; v += 1 {
			old := cluster[v]
			if old < 0 || sampled[old] do continue
			best := m
			for c := 0; c < n; c += 1 {
				candidate := group_best[v*MAX_N+c]
				if sampled[c] && candidate != m && (best == m || bsw_before(edge_w[candidate],edge_u[candidate],edge_v[candidate],edge_w[best],edge_u[best],edge_v[best])) do best = candidate
			}
			if best == m {
				for c := 0; c < n; c += 1 {
					least := group_best[v*MAX_N+c]
					if least == m do continue
					selected[least] = true
					for e := 0; e < m; e += 1 {
						if !active[e] do continue
						a, b := int(edge_u[e]), int(edge_v[e])
						if (a == v && cluster[b] == c) || (b == v && cluster[a] == c) do remove[e] = true
					}
				}
				continue
			}
			a, b := int(edge_u[best]), int(edge_v[best])
			other := a
			if a == v do other = b
			landing := cluster[other]
			next_cluster[v], selected[best] = landing, true
			for c := 0; c < n; c += 1 {
				least := group_best[v*MAX_N+c]
				if least == m do continue
				erase_group := c == landing || edge_w[least] < edge_w[best]
				if c != landing && edge_w[least] < edge_w[best] do selected[least] = true
				if erase_group {
					for e := 0; e < m; e += 1 {
						if !active[e] do continue
						x, y := int(edge_u[e]), int(edge_v[e])
						if (x == v && cluster[y] == c) || (y == v && cluster[x] == c) do remove[e] = true
					}
				}
			}
		}
		for e := 0; e < m; e += 1 do if remove[e] do active[e] = false
		for e := 0; e < m; e += 1 {
			if active[e] {
				u, v := int(edge_u[e]), int(edge_v[e])
				if next_cluster[u] >= 0 && next_cluster[u] == next_cluster[v] do active[e] = false
			}
		}
		for v := 0; v < n; v += 1 do cluster[v] = next_cluster[v]
	}
	var group_best: [MAX_N*MAX_N]int
	for i := 0; i < MAX_N*MAX_N; i += 1 do group_best[i] = m
	for e := 0; e < m; e += 1 {
		if !active[e] do continue
		u, v := int(edge_u[e]), int(edge_v[e])
		if cluster[v] >= 0 {
			slot := u*MAX_N+cluster[v]; prior := group_best[slot]
			if prior == m || bsw_before(edge_w[e],edge_u[e],edge_v[e],edge_w[prior],edge_u[prior],edge_v[prior]) do group_best[slot] = e
		}
		if cluster[u] >= 0 {
			slot := v*MAX_N+cluster[u]; prior := group_best[slot]
			if prior == m || bsw_before(edge_w[e],edge_u[e],edge_v[e],edge_w[prior],edge_u[prior],edge_v[prior]) do group_best[slot] = e
		}
	}
	for v := 0; v < n; v += 1 do if cluster[v] >= 0 {
		for c := 0; c < n; c += 1 { least := group_best[v*MAX_N+c]; if least != m do selected[least] = true }
	}
	for e := 0; e < m; e += 1 {
		if selected[e] do output[e] = 1 else do output[e] = 0
	}
	return i64(m)
}
