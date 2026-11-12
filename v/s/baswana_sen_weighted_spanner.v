module baswana_sen_weighted_spanner

const max_n = 8
const max_m = 28
const max_input = 90

fn bsw_before(aw i64, au i64, av i64, bw i64, bu i64, bv i64) bool {
	return aw < bw || (aw == bw && au < bu) || (aw == bw && au == bu && av < bv)
}

@[export: 'baswana_sen_weighted_spanner']
pub fn baswana_sen_weighted_spanner(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		n64, m64, k := input[0], input[1], input[2]
		if n64 < 2 || n64 > 8 || m64 < 0 || m64 > 28 || k < 2 || k > 3 || length != usize(3+3*(k-1)+3*m64) { return -1 }
		n, m, rounds := int(n64), int(m64), int(k-1)
		mut masks := []i64{len: max_n, init: 0}
		for r in 0 .. rounds {
			masks[r] = input[3+r]
			if masks[r] < 0 || masks[r] >= (i64(1) << n) { return -1 }
		}
		offset := 3+rounds
		mut edge_u := []i64{len: max_m, init: 0}
		mut edge_v := []i64{len: max_m, init: 0}
		mut edge_w := []i64{len: max_m, init: 0}
		mut active := []bool{len: max_m, init: false}
		mut selected := []u8{len: max_m, init: 0}
		for e in 0 .. m {
			edge_u[e], edge_v[e], edge_w[e] = input[offset+3*e], input[offset+3*e+1], input[offset+3*e+2]
			if edge_u[e] < 0 || edge_v[e] <= edge_u[e] || edge_v[e] >= n64 || edge_w[e] < 1 || edge_w[e] > 32 { return -1 }
			for p in 0 .. e { if edge_u[p] == edge_u[e] && edge_v[p] == edge_v[e] { return -1 } }
			active[e] = true
		}
		if output == nil || capacity < m { return -2 }
		mut cluster := []int{len: max_n, init: 0}
		mut next_cluster := []int{len: max_n, init: -1}
		for v in 0 .. n { cluster[v] = v }
		for r in 0 .. rounds {
			mut sampled := []bool{len: max_n, init: false}
			mut remove := []bool{len: max_m, init: false}
			mut group_best := []int{len: max_n*max_n, init: m}
			for v in 0 .. n { next_cluster[v] = -1 }
			for v in 0 .. n {
				center := cluster[v]
				if center >= 0 && ((masks[r] >> center) & 1) != 0 { sampled[center] = true }
			}
			for v in 0 .. n { if cluster[v] >= 0 && sampled[cluster[v]] { next_cluster[v] = cluster[v] } }
			for e in 0 .. m {
				if !active[e] { continue }
				u, v := int(edge_u[e]), int(edge_v[e])
				if cluster[v] >= 0 {
					slot := u*max_n+cluster[v]; prior := group_best[slot]
					if prior == m || bsw_before(edge_w[e],edge_u[e],edge_v[e],edge_w[prior],edge_u[prior],edge_v[prior]) { group_best[slot] = e }
				}
				if cluster[u] >= 0 {
					slot := v*max_n+cluster[u]; prior := group_best[slot]
					if prior == m || bsw_before(edge_w[e],edge_u[e],edge_v[e],edge_w[prior],edge_u[prior],edge_v[prior]) { group_best[slot] = e }
				}
			}
			for v in 0 .. n {
				old := cluster[v]
				if old < 0 || sampled[old] { continue }
				mut best := m
				for c in 0 .. n {
					candidate := group_best[v*max_n+c]
					if sampled[c] && candidate != m && (best == m || bsw_before(edge_w[candidate],edge_u[candidate],edge_v[candidate],edge_w[best],edge_u[best],edge_v[best])) { best = candidate }
				}
				if best == m {
					for c in 0 .. n {
						least := group_best[v*max_n+c]
						if least == m { continue }
						selected[least] = 1
						for e in 0 .. m {
							if !active[e] { continue }
							a, b := int(edge_u[e]), int(edge_v[e])
							if (a == v && cluster[b] == c) || (b == v && cluster[a] == c) { remove[e] = true }
						}
					}
					continue
				}
				a, b := int(edge_u[best]), int(edge_v[best])
				mut other := a
				if a == v { other = b }
				landing := cluster[other]
				next_cluster[v] = landing
				selected[best] = 1
				for c in 0 .. n {
					least := group_best[v*max_n+c]
					if least == m { continue }
					erase_group := c == landing || edge_w[least] < edge_w[best]
					if c != landing && edge_w[least] < edge_w[best] { selected[least] = 1 }
					if erase_group {
						for e in 0 .. m {
							if !active[e] { continue }
							x, y := int(edge_u[e]), int(edge_v[e])
							if (x == v && cluster[y] == c) || (y == v && cluster[x] == c) { remove[e] = true }
						}
					}
				}
			}
			for e in 0 .. m { if remove[e] { active[e] = false } }
			for e in 0 .. m {
				if active[e] {
					u, v := int(edge_u[e]), int(edge_v[e])
					if next_cluster[u] >= 0 && next_cluster[u] == next_cluster[v] { active[e] = false }
				}
			}
			cluster = next_cluster.clone()
		}
		mut group_best := []int{len: max_n*max_n, init: m}
		for e in 0 .. m {
			if !active[e] { continue }
			u, v := int(edge_u[e]), int(edge_v[e])
			if cluster[v] >= 0 {
				slot := u*max_n+cluster[v]; prior := group_best[slot]
				if prior == m || bsw_before(edge_w[e],edge_u[e],edge_v[e],edge_w[prior],edge_u[prior],edge_v[prior]) { group_best[slot] = e }
			}
			if cluster[u] >= 0 {
				slot := v*max_n+cluster[u]; prior := group_best[slot]
				if prior == m || bsw_before(edge_w[e],edge_u[e],edge_v[e],edge_w[prior],edge_u[prior],edge_v[prior]) { group_best[slot] = e }
			}
		}
		for v in 0 .. n { if cluster[v] >= 0 { for c in 0 .. n { least := group_best[v*max_n+c]; if least != m { selected[least] = 1 } } } }
		for e in 0 .. m { output[e] = selected[e] }
		return i64(m)
	}
}
