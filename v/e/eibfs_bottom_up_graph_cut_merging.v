module eibfs_bottom_up_graph_cut_merging

import math

const n_max = 8
const m_max = 24
const input_max = 77
const free_tree = 0
const s_tree = 1
const t_tree = 2

struct State {
	n int
	source int
	sink int
	mut:
	forward bool
	kind [8]int
	parent [8]int
	original [64]i64
	residual [64]i64
	balance [8]i64
	ds [8]i64
	dt [8]i64
	ds_max i64
	dt_max i64
	orphaned [8]bool
	events int
}

fn root(s &State, start int) int {
	mut v := start
	for _ in 0 .. s.n {
		if s.parent[v] < 0 { return v }
		v = s.parent[v]
	}
	return -1
}

fn min64(a i64, b i64) i64 { if a < b { return a }; return b }

fn bottleneck(s &State, start int, kind int) i64 {
	mut v := start
	mut answer := i64(2401)
	for _ in 0 .. s.n {
		p := s.parent[v]
		if p < 0 { return answer }
		cap := s.residual[p * 8 + v]
		if kind == t_tree { cap = s.residual[v * 8 + p] }
		answer = min64(answer, cap)
		v = p
	}
	return 0
}

fn push(mut s State, u int, v int, amount i64) {
	s.residual[u * 8 + v] -= amount
	s.residual[v * 8 + u] += amount
	if u != s.source && u != s.sink { s.balance[u] -= amount }
	if v != s.source && v != s.sink { s.balance[v] += amount }
}

fn mark(mut s State, v int, mut q [512]int, mut tail int) {
	if !s.orphaned[v] { s.orphaned[v] = true; q[tail] = v; tail++ }
}

fn detach(mut s State, v int, kind int, mut q [512]int, mut tail int) {
	for child in 0 .. s.n {
		if s.kind[child] == kind && s.parent[child] == v { s.parent[child] = -1; mark(mut s, child, mut q, mut tail) }
	}
}

fn adopt(mut s State, v int, kind int, mut q [512]int, mut tail int) {
	sink_side := kind == t_tree
	s.orphaned[v] = false
	old := s.ds[v]
	if sink_side { old = s.dt[v] }
	for u in 0 .. s.n {
		cap := s.residual[u * 8 + v]
		here := s.ds[v]
		label := s.ds[u]
		if sink_side { cap = s.residual[v * 8 + u]; here = s.dt[v]; label = s.dt[u] }
		if u != v && s.kind[u] == kind && cap > 0 && here == label + 1 { s.parent[v] = u; return }
	}
	frontier := s.ds_max
	subtract := !s.forward
	if sink_side { frontier = s.dt_max; subtract = s.forward }
	limit := frontier
	if subtract { limit-- }
	mut best := i64(4 * s.n)
	for u in 0 .. s.n {
		cap := s.residual[u * 8 + v]
		label := s.ds[u]
		if sink_side { cap = s.residual[v * 8 + u]; label = s.dt[u] }
		if u != v && s.kind[u] == kind && cap > 0 && label <= limit && label < best { best = label }
	}
	mut parent := -1
	for u in 0 .. s.n {
		cap := s.residual[u * 8 + v]
		label := s.ds[u]
		if sink_side { cap = s.residual[v * 8 + u]; label = s.dt[u] }
		if u != v && s.kind[u] == kind && cap > 0 && label == best { parent = u; break }
	}
	if parent >= 0 && best + 1 > old {
		detach(mut s, v, kind, mut q, mut tail)
		s.parent[v] = parent
		if sink_side { s.dt[v] = best + 1 } else { s.ds[v] = best + 1 }
		return
	}
	detach(mut s, v, kind, mut q, mut tail)
	s.parent[v] = -1
	s.kind[v] = free_tree
	if sink_side && s.balance[v] > 0 {
		s.kind[v] = s_tree
		s.ds[v] = s.ds_max
		if s.forward { s.ds[v]++ }
	} else if !sink_side && s.balance[v] < 0 {
		s.kind[v] = t_tree
		s.dt[v] = s.dt_max
		if !s.forward { s.dt[v]++ }
	}
}

fn repair_orphans(mut s State, kind int, mut q [512]int, mut head int, mut tail int) {
	for head < tail {
		v := q[head]; head++
		s.orphaned[v] = false
		if s.kind[v] == kind { adopt(mut s, v, kind, mut q, mut tail) }
	}
}

fn drain(mut s State, start int, kind int) {
	root_v := root(s, start)
	if root_v < 0 { return }
	mut q := [512]int{}
	mut head := 0
	mut tail := 0
	mut x := start
	for (kind == t_tree && s.balance[x] > 0 || kind == s_tree && s.balance[x] < 0) && s.parent[x] >= 0 {
		p := s.parent[x]
		cap := s.residual[p * 8 + x]
		need := -s.balance[x]
		if kind == t_tree { cap = s.residual[x * 8 + p]; need = s.balance[x] }
		amount := min64(need, cap)
		if amount > 0 { if kind == t_tree { push(mut s, x, p, amount) } else { push(mut s, p, x, amount) } }
		after := -s.balance[x]
		remaining := s.residual[p * 8 + x]
		if kind == t_tree { after = s.balance[x]; remaining = s.residual[x * 8 + p] }
		if remaining == 0 && after >= 0 { s.parent[x] = -1; mark(mut s, x, mut q, mut tail); break }
		if after == 0 { break }
		x = p
	}
	if kind == t_tree && root_v != s.sink && s.kind[root_v] == kind && s.balance[root_v] >= 0 { s.parent[root_v] = -1; mark(mut s, root_v, mut q, mut tail) }
	if kind == s_tree && root_v != s.source && s.kind[root_v] == kind && s.balance[root_v] <= 0 { s.parent[root_v] = -1; mark(mut s, root_v, mut q, mut tail) }
	repair_orphans(mut s, kind, mut q, mut head, mut tail)
}

fn repair(mut s State) {
	for {
		mut found := false
		for v in 0 .. s.n { if s.kind[v] == t_tree && s.balance[v] > 0 { drain(mut s, v, t_tree); found = true; break } }
		if found { continue }
		for v in 0 .. s.n { if s.kind[v] == s_tree && s.balance[v] < 0 { drain(mut s, v, s_tree); found = true; break } }
		if !found { return }
	}
}

fn augment(mut s State, v int, w int) bool {
	rs := root(s, v)
	rt := root(s, w)
	if rs < 0 || rt < 0 || s.residual[v * 8 + w] <= 0 { return false }
	c := s.residual[v * 8 + w]
	bs := bottleneck(s, v, s_tree)
	bt := bottleneck(s, w, t_tree)
	mut amount := c
	if rs == s.source && rt == s.sink {
	} else if rs == s.source { amount = min64(bs, c) }
	else if rt == s.sink { amount = min64(c, bt) }
	else { amount = min64(min64(min64(min64(s.balance[rs], bs), c), bt), -s.balance[rt]) }
	if amount <= 0 { return false }
	push(mut s, v, w, amount)
	repair(mut s)
	return true
}

fn solve(mut s State) i64 {
	mut finished := false
	for _ in 0 .. 4 * s.n + 4 {
		if finished { break }
		for {
			mut restart := false
			if s.forward {
				for v in 0 .. s.n {
					if restart { break }
					if s.kind[v] != s_tree || s.ds[v] != s.ds_max { continue }
					for w in 0 .. s.n {
						if s.residual[v * 8 + w] <= 0 || s.kind[w] == s_tree { continue }
						if s.kind[w] == free_tree { s.kind[w] = s_tree; s.parent[w] = v; s.ds[w] = s.ds_max + 1 }
						else if s.kind[w] == t_tree && augment(mut s, v, w) { s.events++; if s.events > 100000 { return -1 }; restart = true; break }
					}
				}
				if !restart {
					mut next := false
					for v in 0 .. s.n { if s.kind[v] == s_tree && s.ds[v] == s.ds_max + 1 { next = true } }
					if next { s.ds_max++ } else { finished = true }
					break
				}
			} else {
				for w in 0 .. s.n {
					if restart { break }
					if s.kind[w] != t_tree || s.dt[w] != s.dt_max { continue }
					for v in 0 .. s.n {
						if s.residual[v * 8 + w] <= 0 || s.kind[v] == t_tree { continue }
						if s.kind[v] == free_tree { s.kind[v] = t_tree; s.parent[v] = w; s.dt[v] = s.dt_max + 1 }
						else if s.kind[v] == s_tree && augment(mut s, v, w) { s.events++; if s.events > 100000 { return -1 }; restart = true; break }
					}
				}
				if !restart {
					mut next := false
					for v in 0 .. s.n { if s.kind[v] == t_tree && s.dt[v] == s.dt_max + 1 { next = true } }
					if next { s.dt_max++ } else { finished = true }
					break
				}
			}
		}
		if !finished { s.forward = !s.forward }
	}
	mut reachable := [8]bool{}
	mut queue := [8]int{}
	mut head := 0
	mut tail := 0
	for v in 0 .. s.n { if s.kind[v] == s_tree { reachable[v] = true; queue[tail] = v; tail++ } }
	for head < tail {
		u := queue[head]; head++
		for v in 0 .. s.n { if s.residual[u * 8 + v] > 0 && !reachable[v] { reachable[v] = true; queue[tail] = v; tail++ } }
	}
	mut cut := i64(0)
	for u in 0 .. s.n { if reachable[u] { for v in 0 .. s.n { if !reachable[v] { cut += s.original[u * 8 + v] } } } }
	return cut
}

fn eibfs_maxflow_frame(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 4 || length > input_max { return -1 }
	unsafe {
		nv,mv,sv,tv := input[0],input[1],input[2],input[3]
		if nv < 2 || nv > n_max || mv < 0 || mv > m_max || sv < 0 || sv >= nv || tv < 0 || tv >= nv || sv == tv { return -1 }
		n,m,source,sink := int(nv),int(mv),int(sv),int(tv)
		if length != usize(4 + 3 * m) { return -1 }
		mut s := State{n: n, source: source, sink: sink, forward: true}
		for v in 0 .. n { s.parent[v] = -1 }
		for e in 0 .. m {
			u,v,capacity := input[4 + 3 * e],input[5 + 3 * e],input[6 + 3 * e]
			if u < 0 || u >= nv || v < 0 || v >= nv || u == v || capacity < 0 || capacity > 100 { return -1 }
			s.original[int(u) * 8 + int(v)] += capacity
			s.residual[int(u) * 8 + int(v)] += capacity
		}
		s.kind[source] = s_tree
		s.kind[sink] = t_tree
		return solve(mut s)
	}
}

fn peibfs_find(parent [4]int, block int) int {
	mut root := block
	for _ in 0 .. 4 {
		if parent[root] == root { return root }
		root = parent[root]
	}
	return root
}

fn peibfs_component_flow(n int, m int, active [4]bool, block_ids [6]int,
	source_caps [6]i64, sink_caps [6]i64, edge_u [6]int, edge_v [6]int,
	edge_uv [6]i64, edge_vu [6]i64) i64 {
	mut local := [6]int{}
	mut vertices := [6]int{}
	for v in 0 .. n { local[v] = -1 }
	mut k := 0
	for v in 0 .. n {
		if active[block_ids[v]] { local[v] = k; vertices[k] = v; k++ }
	}
	mut internal_edges := 0
	for e in 0 .. m { if local[edge_u[e]] >= 0 && local[edge_v[e]] >= 0 { internal_edges++ } }
	mut frame := [77]i64{}
	source, sink := k, k + 1
	frame[0], frame[1], frame[2], frame[3] = i64(k + 2), i64(2 * k + 2 * internal_edges), i64(source), i64(sink)
	mut at := 4
	for i in 0 .. k {
		v := vertices[i]
		frame[at], frame[at + 1], frame[at + 2] = i64(source), i64(i), source_caps[v]
		at += 3
		frame[at], frame[at + 1], frame[at + 2] = i64(i), i64(sink), sink_caps[v]
		at += 3
	}
	for e in 0 .. m {
		u, v := edge_u[e], edge_v[e]
		if local[u] >= 0 && local[v] >= 0 {
			frame[at], frame[at + 1], frame[at + 2] = i64(local[u]), i64(local[v]), edge_uv[e]
			at += 3
			frame[at], frame[at + 1], frame[at + 2] = i64(local[v]), i64(local[u]), edge_vu[e]
			at += 3
		}
	}
	return unsafe { eibfs_maxflow_frame(&frame[0], usize(at)) }
}

@[export: 'eibfs_bottom_up_graph_cut_merging']
pub fn eibfs_bottom_up_graph_cut_merging(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < usize(3) || length > usize(46) { return -1 }
	unsafe {
		nv, mv, bv := input[0], input[1], input[2]
		if nv < 2 || nv > 6 || mv < 0 || mv > 6 || bv < 1 || bv > 4 || bv > nv { return -1 }
		n, m, blocks := int(nv), int(mv), int(bv)
		if length != usize(3 + 3 * n + 4 * m) { return -1 }
		mut block_ids := [6]int{}
		mut source_caps := [6]i64{}
		mut sink_caps := [6]i64{}
		mut edge_u := [6]int{}
		mut edge_v := [6]int{}
		mut edge_uv := [6]i64{}
		mut edge_vu := [6]i64{}
		mut present := [4]bool{}
		for v in 0 .. n {
			block, sc, tc := input[3 + v], input[3 + n + v], input[3 + 2 * n + v]
			if block < 0 || block >= bv || sc < 0 || sc > 7 || tc < 0 || tc > 7 { return -1 }
			block_ids[v], source_caps[v], sink_caps[v] = int(block), sc, tc
			present[int(block)] = true
		}
		for b in 0 .. blocks { if !present[b] { return -1 } }
		edges_at := 3 + 3 * n
		for e in 0 .. m {
			u, v := input[edges_at + 4 * e], input[edges_at + 4 * e + 1]
			uv, vu := input[edges_at + 4 * e + 2], input[edges_at + 4 * e + 3]
			if u < 0 || u >= nv || v < 0 || v >= nv || u == v || uv < 0 || uv > 7 || vu < 0 || vu > 7 { return -1 }
			edge_u[e], edge_v[e], edge_uv[e], edge_vu[e] = int(u), int(v), uv, vu
		}

		mut tags := [6]int{}
		mut component_flow := [4]i64{}
		mut active := [4]bool{}
		for block in 0 .. blocks {
			mut vertices := [6]int{}
			mut local := [6]int{}
			for v in 0 .. n { local[v] = -1 }
			mut k := 0
			for v in 0 .. n {
				if block_ids[v] == block { vertices[k], local[v] = v, k; k++ }
			}
			mut best_cost := i64(9223372036854775807)
			mut best_mask := 0
			for mask in 0 .. (1 << k) {
				mut cost := i64(0)
				for i in 0 .. k {
					v := vertices[i]
					if (mask & (1 << i)) != 0 { cost += sink_caps[v] } else { cost += source_caps[v] }
				}
				for e in 0 .. m {
					u, v := edge_u[e], edge_v[e]
					ui, vi := local[u], local[v]
					if ui >= 0 && vi >= 0 {
						u_side, v_side := (mask & (1 << ui)) != 0, (mask & (1 << vi)) != 0
						if u_side && !v_side { cost += edge_uv[e] } else if v_side && !u_side { cost += edge_vu[e] }
					}
				}
				if cost < best_cost { best_cost, best_mask = cost, mask }
			}
			for i in 0 .. k { if (best_mask & (1 << i)) != 0 { tags[vertices[i]] = 1 } else { tags[vertices[i]] = 2 } }
			active[block] = true
			component_flow[block] = peibfs_component_flow(n, m, active, block_ids, source_caps, sink_caps, edge_u, edge_v, edge_uv, edge_vu)
			if component_flow[block] < 0 { return -1 }
			active[block] = false
		}

		mut pair_a := [6]int{}
		mut pair_b := [6]int{}
		mut pair_score := [6]i64{}
		mut pair_count := 0
		for e in 0 .. m {
			u, v := edge_u[e], edge_v[e]
			a0, b0 := block_ids[u], block_ids[v]
			if a0 == b0 || (edge_uv[e] == 0 && edge_vu[e] == 0) { continue }
			mut a, b := a0, b0
			if a > b { a, b = b, a }
			mut found := -1
			for i in 0 .. pair_count { if pair_a[i] == a && pair_b[i] == b { found = i } }
			if found < 0 { found = pair_count; pair_count++; pair_a[found], pair_b[found] = a, b }
			if tags[u] != tags[v] {
				if edge_uv[e] > 0 { pair_score[found]++ }
				if edge_vu[e] > 0 { pair_score[found]++ }
			}
		}
		for i in 0 .. pair_count {
			for j in i + 1 .. pair_count {
				precedes := pair_score[j] > pair_score[i] || (pair_score[j] == pair_score[i] && (pair_a[j] < pair_a[i] || (pair_a[j] == pair_a[i] && pair_b[j] < pair_b[i])))
				if precedes {
					pair_a[i], pair_a[j] = pair_a[j], pair_a[i]
					pair_b[i], pair_b[j] = pair_b[j], pair_b[i]
					pair_score[i], pair_score[j] = pair_score[j], pair_score[i]
				}
			}
		}

		mut parent := [4]int{}
		for b in 0 .. blocks { parent[b] = b }
		for i in 0 .. pair_count {
			root_a, root_b := peibfs_find(parent, pair_a[i]), peibfs_find(parent, pair_b[i])
			if root_a == root_b { continue }
			mut root, other := root_a, root_b
			if root > other { root, other = other, root }
			parent[other] = root
			for b in 0 .. blocks { active[b] = peibfs_find(parent, b) == root }
			component_flow[root] = peibfs_component_flow(n, m, active, block_ids, source_caps, sink_caps, edge_u, edge_v, edge_uv, edge_vu)
			if component_flow[root] < 0 { return -1 }
			component_flow[other] = 0
		}
		mut answer := i64(0)
		for b in 0 .. blocks { if peibfs_find(parent, b) == b { answer += component_flow[b] } }
		return answer
	}
}
