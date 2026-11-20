package dual_decomposition_graph_cut_maxflow

import "core:c"

MAX_N :: 6
MAX_M :: 10
STRIDE :: 8
OFFSET :: i64(7000)
SCALES :: [9]i64{0, 2, 2, 6, 12, 60, 60, 420, 840}

dd_member :: proc(owner, side: int) -> bool { return owner == side || owner == 2 }

dd_solve :: proc(side, n, m: int, owner: [MAX_N]int, source_cap, sink_cap: [MAX_N]i64,
		eu, ev: [MAX_M]int, uv, vu: [MAX_M]i64, lambda: [MAX_N]i64, scale: i64,
		labels: ^[MAX_N]i64) -> i64 {
	source, sink, size := n, n + 1, n + 2
	residual: [STRIDE * STRIDE]i64
	constant, flow, source_sum, lambda_sum := i64(0), i64(0), i64(0), i64(0)
	for u := 0; u < n; u += 1 {
		source_sum += source_cap[u]
		if dd_member(owner[u], side) {
			factor := if owner[u] == 2 do scale / 2 else scale
			residual[source * STRIDE + u] += source_cap[u] * factor
			residual[u * STRIDE + sink] += sink_cap[u] * factor
		}
		if owner[u] == 2 { if lambda[u] < 0 { lambda_sum -= lambda[u] } else { lambda_sum += lambda[u] } }
	}
	for i := 0; i < m; i += 1 {
		if dd_member(owner[eu[i]], side) && dd_member(owner[ev[i]], side) {
			factor := if owner[eu[i]] == 2 && owner[ev[i]] == 2 do scale / 2 else scale
			residual[eu[i] * STRIDE + ev[i]] += uv[i] * factor
			residual[ev[i] * STRIDE + eu[i]] += vu[i] * factor
		}
	}
	for u := 0; u < n; u += 1 {
		if owner[u] == 2 {
			q := if side == 0 do lambda[u] else -lambda[u]
			if q >= 0 { residual[source * STRIDE + u] += q }
			else { residual[u * STRIDE + sink] += -q; constant += q }
		}
	}
	for {
		parent: [STRIDE]int
		queue: [STRIDE]int
		for i := 0; i < size; i += 1 { parent[i] = -1 }
		parent[source] = source
		head, tail := 0, 0
		queue[tail] = source; tail += 1
		for head < tail && parent[sink] < 0 {
			u := queue[head]; head += 1
			for v := 0; v < size; v += 1 {
				if parent[v] < 0 && residual[u * STRIDE + v] > 0 {
					parent[v] = u; queue[tail] = v; tail += 1
					if v == sink do break
				}
			}
		}
		if parent[sink] < 0 {
			for u := 0; u < n; u += 1 { labels[u] = 0; if dd_member(owner[u], side) && parent[u] < 0 { labels[u] = 1 } }
			return flow + constant
		}
		amount := source_sum * scale + lambda_sum + 1
		v := sink
		for v != source { u := parent[v]; if residual[u * STRIDE + v] < amount { amount = residual[u * STRIDE + v] }; v = u }
		v = sink
		for v != source { u := parent[v]; residual[u * STRIDE + v] -= amount; residual[v * STRIDE + u] += amount; v = u }
		flow += amount
	}
}

@(export)
dual_decomposition_graph_cut_maxflow :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 63 do return -1
	rn, rm, ro, rt := input[0], input[1], input[2], input[3]
	if rn < 3 || rn > MAX_N || rm < 0 || rm > MAX_M || ro < 1 || ro > 3 || rt < 1 || rt > 8 ||
		length != c.size_t(4 + 3 * rn + 4 * rm) do return -1
	n, m, overlap, rounds := int(rn), int(rm), int(ro), int(rt)
	at := 4
	owner: [MAX_N]int
	counts: [3]int
	for u := 0; u < n; u += 1 {
		x := input[at]; at += 1
		if x < 0 || x > 2 do return -1
		owner[u] = int(x); counts[owner[u]] += 1
	}
	if counts[0] == 0 || counts[1] == 0 || counts[2] != overlap do return -1
	source_cap, sink_cap: [MAX_N]i64
	for u := 0; u < n; u += 1 { source_cap[u] = input[at]; at += 1; if source_cap[u] < 0 || source_cap[u] > 6 || source_cap[u] % 2 != 0 do return -1 }
	for u := 0; u < n; u += 1 { sink_cap[u] = input[at]; at += 1; if sink_cap[u] < 0 || sink_cap[u] > 6 || sink_cap[u] % 2 != 0 do return -1 }
	eu, ev: [MAX_M]int
	uv, vu: [MAX_M]i64
	for i := 0; i < m; i += 1 {
		ru, rv, c, d := input[at], input[at+1], input[at+2], input[at+3]; at += 4
		if ru < 0 || ru >= rn || rv < 0 || rv >= rn || ru == rv ||
			(owner[int(ru)] == 0 && owner[int(rv)] == 1) || (owner[int(ru)] == 1 && owner[int(rv)] == 0) ||
			c < 0 || c > 6 || c % 2 != 0 || d < 0 || d > 6 || d % 2 != 0 do return -1
		eu[i], ev[i], uv[i], vu[i] = int(ru), int(rv), c, d
	}
	scale := SCALES[rounds]
	lambda, labels_m, labels_n: [MAX_N]i64
	agreement := false
	dual_scaled := i64(0)
	for iteration := 1; iteration <= rounds; iteration += 1 {
		energy_m := dd_solve(0,n,m,owner,source_cap,sink_cap,eu,ev,uv,vu,lambda,scale,&labels_m)
		energy_n := dd_solve(1,n,m,owner,source_cap,sink_cap,eu,ev,uv,vu,lambda,scale,&labels_n)
		dual_scaled = energy_m + energy_n
		agreement = true
		for u := 0; u < n; u += 1 { if owner[u] == 2 && labels_m[u] != labels_n[u] { agreement = false } }
		if agreement || iteration == rounds do break
		step := scale / i64(iteration)
		for u := 0; u < n; u += 1 { if owner[u] == 2 { lambda[u] += step * (labels_m[u] - labels_n[u]) } }
	}
	agree_value := i64(0)
	if agreement { agree_value = 1 }
	return 2 * (dual_scaled + OFFSET) + agree_value
}
