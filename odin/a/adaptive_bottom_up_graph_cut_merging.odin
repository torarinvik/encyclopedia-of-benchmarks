package adaptive_bottom_up_graph_cut_merging

import "core:c"

MAX_N :: 8
MAX_M :: 16
MAX_B :: 4
STRIDE :: 10

abm_allowed :: proc(u, v, n: int, allowed: [8]bool) -> bool {
	if u < n && !allowed[u] do return false
	if v < n && !allowed[v] do return false
	return v != n && u != n + 1
}

abm_augment :: proc(residual: ^[100]i64, n: int, allowed: [8]bool) {
	source, sink := n, n + 1
	for {
		parent: [10]int
		for i := 0; i < STRIDE; i += 1 do parent[i] = -1
		queue: [10]int
		parent[source] = source
		head, tail := 0, 0
		queue[tail] = source
		tail += 1
		for head < tail && parent[sink] < 0 {
			u := queue[head]
			head += 1
			for v := 0; v < n + 2; v += 1 {
				if parent[v] < 0 && residual[u * STRIDE + v] > 0 && abm_allowed(u, v, n, allowed) {
					parent[v] = u
					queue[tail] = v
					tail += 1
					if v == sink do break
				}
			}
		}
		if parent[sink] < 0 do return
		amount := i64(n * 7)
		v := sink
		for v != source {
			u := parent[v]
			if residual[u * STRIDE + v] < amount do amount = residual[u * STRIDE + v]
			v = u
		}
		v = sink
		for v != source {
			u := parent[v]
			residual[u * STRIDE + v] -= amount
			residual[v * STRIDE + u] += amount
			v = u
		}
	}
}

@(export)
adaptive_bottom_up_graph_cut_merging :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 92 do return -1
	raw_n, raw_m, raw_b := input[0], input[1], input[2]
	if raw_n < 2 || raw_n > MAX_N || raw_m < 0 || raw_m > MAX_M || raw_b < 1 || raw_b > MAX_B || raw_b > raw_n ||
		length != c.size_t(3 + 3 * raw_n + 4 * raw_m) do return -1
	n, m, bcount := int(raw_n), int(raw_m), int(raw_b)
	at := 3
	block: [MAX_N]int
	seen: [MAX_B]bool
	source_cap, sink_cap: [MAX_N]i64
	for u := 0; u < n; u += 1 {
		x := input[at]
		at += 1
		if x < 0 || x >= raw_b do return -1
		block[u] = int(x)
		seen[block[u]] = true
	}
	for b := 0; b < bcount; b += 1 do if !seen[b] do return -1
	for u := 0; u < n; u += 1 { source_cap[u] = input[at]; at += 1; if source_cap[u] < 0 || source_cap[u] > 7 do return -1 }
	for u := 0; u < n; u += 1 { sink_cap[u] = input[at]; at += 1; if sink_cap[u] < 0 || sink_cap[u] > 7 do return -1 }

	eu, ev, ba, bb: [MAX_M]int
	uv, vu: [MAX_M]i64
	cross, enabled: [MAX_M]bool
	residual: [100]i64
	for u := 0; u < n; u += 1 { residual[n * STRIDE + u] += source_cap[u]; residual[u * STRIDE + n + 1] += sink_cap[u] }
	potential: [MAX_B * MAX_B]i64
	present: [MAX_B * MAX_B]bool
	for i := 0; i < m; i += 1 {
		ru, rv, rc, rd := input[at], input[at + 1], input[at + 2], input[at + 3]
		at += 4
		if ru < 0 || ru >= raw_n || rv < 0 || rv >= raw_n || ru == rv || rc < 0 || rc > 7 || rd < 0 || rd > 7 do return -1
		u, v := int(ru), int(rv)
		eu[i], ev[i], uv[i], vu[i] = u, v, rc, rd
		if block[u] == block[v] {
			residual[u * STRIDE + v] += rc
			residual[v * STRIDE + u] += rd
		} else {
			ba[i] = min(block[u], block[v]); bb[i] = max(block[u], block[v])
			cross[i] = rc != 0 || rd != 0
			if cross[i] do present[ba[i] * MAX_B + bb[i]] = true
		}
	}
	allowed: [MAX_N]bool
	for b := 0; b < bcount; b += 1 {
		for u := 0; u < n; u += 1 do allowed[u] = block[u] == b
		abm_augment(&residual, n, allowed)
	}
	tag: [MAX_N]int
	for b := 0; b < bcount; b += 1 {
		for u := 0; u < n; u += 1 do allowed[u] = block[u] == b
		ss, tt: [STRIDE]bool
		queue: [STRIDE]int
		head, tail := 0, 0
		ss[n] = true; queue[tail] = n; tail += 1
		for head < tail {
			u := queue[head]; head += 1
			for v := 0; v < n + 2; v += 1 {
				if !ss[v] && residual[u * STRIDE + v] > 0 && (u >= n || allowed[u]) && (v >= n || allowed[v]) { ss[v] = true; queue[tail] = v; tail += 1 }
			}
		}
		head, tail = 0, 0
		tt[n + 1] = true; queue[tail] = n + 1; tail += 1
		for head < tail {
			v := queue[head]; head += 1
			for u := 0; u < n + 2; u += 1 {
				if !tt[u] && residual[u * STRIDE + v] > 0 && (u >= n || allowed[u]) && (v >= n || allowed[v]) { tt[u] = true; queue[tail] = u; tail += 1 }
			}
		}
		for u := 0; u < n; u += 1 do if allowed[u] { tag[u] = if ss[u] { 1 } else if tt[u] { 2 } else { 0 } }
	}
	for i := 0; i < m; i += 1 {
		if cross[i] && tag[eu[i]] != tag[ev[i]] {
			if uv[i] > 0 do potential[ba[i] * MAX_B + bb[i]] += 1
			if vu[i] > 0 do potential[ba[i] * MAX_B + bb[i]] += 1
		}
	}
	order_a, order_b: [MAX_B * MAX_B]int
	order_n := 0
	for a := 0; a < bcount; a += 1 {
		for b := a + 1; b < bcount; b += 1 {
			if !present[a * MAX_B + b] do continue
			p := order_n; order_n += 1
			for p > 0 {
				pa, pb := order_a[p - 1], order_b[p - 1]
				if potential[pa * MAX_B + pb] > potential[a * MAX_B + b] ||
					(potential[pa * MAX_B + pb] == potential[a * MAX_B + b] && (pa < a || (pa == a && pb <= b))) do break
				order_a[p], order_b[p] = pa, pb
				p -= 1
			}
			order_a[p], order_b[p] = a, b
		}
	}
	parent: [MAX_B]int
	for b := 0; b < bcount; b += 1 do parent[b] = b
	for oi := 0; oi < order_n; oi += 1 {
		a, b := order_a[oi], order_b[oi]
		for parent[a] != a do a = parent[a]
		for parent[b] != b do b = parent[b]
		if a == b do continue
		root, other := min(a, b), max(a, b)
		parent[other] = root
		for i := 0; i < m; i += 1 do if cross[i] && !enabled[i] {
			x, y := ba[i], bb[i]
			for parent[x] != x do x = parent[x]
			for parent[y] != y do y = parent[y]
			if x == y { residual[eu[i] * STRIDE + ev[i]] += uv[i]; residual[ev[i] * STRIDE + eu[i]] += vu[i]; enabled[i] = true }
		}
		for u := 0; u < n; u += 1 {
			x := block[u]
			for parent[x] != x do x = parent[x]
			allowed[u] = x == root
		}
		abm_augment(&residual, n, allowed)
	}
	flow: i64 = 0
	for u := 0; u < n; u += 1 do flow += source_cap[u] - residual[n * STRIDE + u]
	return flow
}
