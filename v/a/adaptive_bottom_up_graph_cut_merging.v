module adaptive_bottom_up_graph_cut_merging

const max_n = 8
const max_m = 16
const max_b = 4
const stride = 10

fn abm_allowed(u int, v int, n int, allowed [8]bool) bool {
	if u < n && !allowed[u] { return false }
	if v < n && !allowed[v] { return false }
	return v != n && u != n + 1
}

fn abm_augment(mut residual [100]i64, n int, allowed [8]bool) {
	source := n
	sink := n + 1
	for {
		mut parent := [stride]int{}
		mut queue := [stride]int{}
		for i in 0 .. stride { parent[i] = -1 }
		parent[source] = source
		mut head := 0
		mut tail := 1
		queue[0] = source
		for head < tail && parent[sink] < 0 {
			u := queue[head]
			head++
			for v in 0 .. n + 2 {
				if parent[v] < 0 && residual[u * stride + v] > 0 && abm_allowed(u, v, n, allowed) {
					parent[v] = u
					queue[tail] = v
					tail++
					if v == sink { break }
				}
			}
		}
		if parent[sink] < 0 { return }
		mut amount := i64(n * 7)
		mut v := sink
		for v != source {
			u := parent[v]
			if residual[u * stride + v] < amount { amount = residual[u * stride + v] }
			v = u
		}
		v = sink
		for v != source {
			u := parent[v]
			residual[u * stride + v] -= amount
			residual[v * stride + u] += amount
			v = u
		}
	}
}

@[export: 'adaptive_bottom_up_graph_cut_merging']
pub fn adaptive_bottom_up_graph_cut_merging(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 3 || length > 92 { return -1 }
	raw_n := unsafe { input[0] }
	raw_m := unsafe { input[1] }
	raw_b := unsafe { input[2] }
	if raw_n < 2 || raw_n > max_n || raw_m < 0 || raw_m > max_m || raw_b < 1 || raw_b > max_b || raw_b > raw_n ||
		length != usize(3 + 3 * raw_n + 4 * raw_m) { return -1 }
	n, m, bcount := int(raw_n), int(raw_m), int(raw_b)
	mut at := 3
	mut block := [max_n]int{}
	mut seen := [max_b]bool{}
	mut source_cap := [max_n]i64{}
	mut sink_cap := [max_n]i64{}
	for u in 0 .. n {
		x := unsafe { input[at] }; at++
		if x < 0 || x >= raw_b { return -1 }
		block[u] = int(x); seen[block[u]] = true
	}
	for b in 0 .. bcount { if !seen[b] { return -1 } }
	for u in 0 .. n { source_cap[u] = unsafe { input[at] }; at++; if source_cap[u] < 0 || source_cap[u] > 7 { return -1 } }
	for u in 0 .. n { sink_cap[u] = unsafe { input[at] }; at++; if sink_cap[u] < 0 || sink_cap[u] > 7 { return -1 } }
	mut eu, ev, ba, bb := [max_m]int{}, [max_m]int{}, [max_m]int{}, [max_m]int{}
	mut uv, vu := [max_m]i64{}, [max_m]i64{}
	mut cross, enabled := [max_m]bool{}, [max_m]bool{}
	mut residual := [stride * stride]i64{}
	for u in 0 .. n { residual[n * stride + u] += source_cap[u]; residual[u * stride + n + 1] += sink_cap[u] }
	mut potential := [max_b * max_b]i64{}
	mut present := [max_b * max_b]bool{}
	for i in 0 .. m {
		ru, rv, rc, rd := unsafe { input[at] }, unsafe { input[at + 1] }, unsafe { input[at + 2] }, unsafe { input[at + 3] }
		at += 4
		if ru < 0 || ru >= raw_n || rv < 0 || rv >= raw_n || ru == rv || rc < 0 || rc > 7 || rd < 0 || rd > 7 { return -1 }
		u, v := int(ru), int(rv); eu[i], ev[i], uv[i], vu[i] = u, v, rc, rd
		if block[u] == block[v] { residual[u * stride + v] += rc; residual[v * stride + u] += rd }
		else { ba[i], bb[i] = min(block[u], block[v]), max(block[u], block[v]); cross[i] = rc != 0 || rd != 0; if cross[i] { present[ba[i] * max_b + bb[i]] = true } }
	}
	mut allowed := [max_n]bool{}
	for b in 0 .. bcount { for u in 0 .. n { allowed[u] = block[u] == b }; abm_augment(mut residual, n, allowed) }
	mut tag := [max_n]int{}
	for b in 0 .. bcount {
		for u in 0 .. n { allowed[u] = block[u] == b }
		mut ss, tt := [stride]bool{}, [stride]bool{}
		mut queue := [stride]int{}
		mut head, tail := 0, 1; ss[n] = true; queue[0] = n
		for head < tail { u := queue[head]; head++; for v in 0 .. n + 2 { if !ss[v] && residual[u * stride + v] > 0 && (u >= n || allowed[u]) && (v >= n || allowed[v]) { ss[v] = true; queue[tail] = v; tail++ } } }
		head, tail = 0, 1; tt[n + 1] = true; queue[0] = n + 1
		for head < tail { v := queue[head]; head++; for u in 0 .. n + 2 { if !tt[u] && residual[u * stride + v] > 0 && (u >= n || allowed[u]) && (v >= n || allowed[v]) { tt[u] = true; queue[tail] = u; tail++ } } }
		for u in 0 .. n { if allowed[u] { tag[u] = if ss[u] { 1 } else if tt[u] { 2 } else { 0 } } }
	}
	for i in 0 .. m { if cross[i] && tag[eu[i]] != tag[ev[i]] { if uv[i] > 0 { potential[ba[i] * max_b + bb[i]]++ }; if vu[i] > 0 { potential[ba[i] * max_b + bb[i]]++ } } }
	mut order_a, order_b := [max_b * max_b]int{}, [max_b * max_b]int{}
	mut order_n := 0
	for a in 0 .. bcount { for b in a + 1 .. bcount { if present[a * max_b + b] { mut p := order_n; order_n++; for p > 0 { pa, pb := order_a[p - 1], order_b[p - 1]; if potential[pa * max_b + pb] > potential[a * max_b + b] || (potential[pa * max_b + pb] == potential[a * max_b + b] && (pa < a || (pa == a && pb <= b))) { break }; order_a[p], order_b[p] = pa, pb; p-- }; order_a[p], order_b[p] = a, b } } }
	mut parent := [max_b]int{}
	for b in 0 .. bcount { parent[b] = b }
	for oi in 0 .. order_n {
		mut a, b := order_a[oi], order_b[oi]
		for parent[a] != a { a = parent[a] }; for parent[b] != b { b = parent[b] }
		if a == b { continue }
		root, other := min(a, b), max(a, b); parent[other] = root
		for i in 0 .. m { if cross[i] && !enabled[i] { mut x, y := ba[i], bb[i]; for parent[x] != x { x = parent[x] }; for parent[y] != y { y = parent[y] }; if x == y { residual[eu[i] * stride + ev[i]] += uv[i]; residual[ev[i] * stride + eu[i]] += vu[i]; enabled[i] = true } } }
		for u in 0 .. n { mut x := block[u]; for parent[x] != x { x = parent[x] }; allowed[u] = x == root }
		abm_augment(mut residual, n, allowed)
	}
	mut flow := i64(0)
	for u in 0 .. n { flow += source_cap[u] - residual[n * stride + u] }
	return flow
}
