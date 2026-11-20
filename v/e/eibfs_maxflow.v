module eibfs_maxflow

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

@[export: 'eibfs_maxflow']
pub fn eibfs_maxflow(input &i64, length usize) i64 {
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
