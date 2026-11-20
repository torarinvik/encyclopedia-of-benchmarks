module dual_decomposition_graph_cut_maxflow

const max_n = 6
const max_m = 10
const stride = 8
const offset = i64(7000)
const scales = [9]i64{0, 2, 2, 6, 12, 60, 60, 420, 840}

fn dd_member(owner int, side int) bool { return owner == side || owner == 2 }

fn dd_solve(side int, n int, m int, owner [max_n]int,
	source_cap [max_n]i64, sink_cap [max_n]i64, eu [max_m]int, ev [max_m]int,
	uv [max_m]i64, vu [max_m]i64, lambda [max_n]i64, scale i64,
	mut labels [max_n]i64) i64 {
	source := n
	sink := n + 1
	size := n + 2
	mut residual := [stride * stride]i64{}
	mut constant := i64(0)
	mut flow := i64(0)
	mut source_sum := i64(0)
	mut lambda_sum := i64(0)
	for u in 0 .. n {
		source_sum += source_cap[u]
		if dd_member(owner[u], side) {
			factor := if owner[u] == 2 { scale / 2 } else { scale }
			residual[source * stride + u] += source_cap[u] * factor
			residual[u * stride + sink] += sink_cap[u] * factor
		}
		if owner[u] == 2 { if lambda[u] < 0 { lambda_sum -= lambda[u] } else { lambda_sum += lambda[u] } }
	}
	for i in 0 .. m {
		if dd_member(owner[eu[i]], side) && dd_member(owner[ev[i]], side) {
			factor := if owner[eu[i]] == 2 && owner[ev[i]] == 2 { scale / 2 } else { scale }
			residual[eu[i] * stride + ev[i]] += uv[i] * factor
			residual[ev[i] * stride + eu[i]] += vu[i] * factor
		}
	}
	for u in 0 .. n {
		if owner[u] == 2 {
			q := if side == 0 { lambda[u] } else { -lambda[u] }
			if q >= 0 { residual[source * stride + u] += q }
			else { residual[u * stride + sink] += -q; constant += q }
		}
	}
	for {
		mut parent := [stride]int{}
		mut queue := [stride]int{}
		for i in 0 .. size { parent[i] = -1 }
		parent[source] = source
		mut head := 0
		mut tail := 1
		queue[0] = source
		for head < tail && parent[sink] < 0 {
			u := queue[head]; head++
			for v in 0 .. size {
				if parent[v] < 0 && residual[u * stride + v] > 0 {
					parent[v] = u; queue[tail] = v; tail++
					if v == sink { break }
				}
			}
		}
		if parent[sink] < 0 {
			for u in 0 .. n { labels[u] = if dd_member(owner[u], side) && parent[u] < 0 { 1 } else { 0 } }
			return flow + constant
		}
		mut amount := source_sum * scale + lambda_sum + 1
		mut v := sink
		for v != source { u := parent[v]; amount = min(amount, residual[u * stride + v]); v = u }
		v = sink
		for v != source { u := parent[v]; residual[u * stride + v] -= amount; residual[v * stride + u] += amount; v = u }
		flow += amount
	}
}

@[export: 'dual_decomposition_graph_cut_maxflow']
pub fn dual_decomposition_graph_cut_maxflow(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 4 || length > 63 { return -1 }
	rn := unsafe { input[0] }; rm := unsafe { input[1] }; ro := unsafe { input[2] }; rt := unsafe { input[3] }
	if rn < 3 || rn > max_n || rm < 0 || rm > max_m || ro < 1 || ro > 3 || rt < 1 || rt > 8 ||
		length != usize(4 + 3 * rn + 4 * rm) { return -1 }
	n, m, overlap, rounds := int(rn), int(rm), int(ro), int(rt)
	mut at := 4
	mut owner := [max_n]int{}
	mut counts := [3]int{}
	for u in 0 .. n {
		x := unsafe { input[at] }; at++
		if x < 0 || x > 2 { return -1 }
		owner[u] = int(x); counts[owner[u]]++
	}
	if counts[0] == 0 || counts[1] == 0 || counts[2] != overlap { return -1 }
	mut source_cap, sink_cap := [max_n]i64{}, [max_n]i64{}
	for u in 0 .. n { source_cap[u] = unsafe { input[at] }; at++; if source_cap[u] < 0 || source_cap[u] > 6 || source_cap[u] % 2 != 0 { return -1 } }
	for u in 0 .. n { sink_cap[u] = unsafe { input[at] }; at++; if sink_cap[u] < 0 || sink_cap[u] > 6 || sink_cap[u] % 2 != 0 { return -1 } }
	mut eu, ev := [max_m]int{}, [max_m]int{}
	mut uv, vu := [max_m]i64{}, [max_m]i64{}
	for i in 0 .. m {
		ru, rv, c, d := unsafe { input[at] }, unsafe { input[at+1] }, unsafe { input[at+2] }, unsafe { input[at+3] }; at += 4
		if ru < 0 || ru >= rn || rv < 0 || rv >= rn || ru == rv || (owner[int(ru)] == 0 && owner[int(rv)] == 1) || (owner[int(ru)] == 1 && owner[int(rv)] == 0) || c < 0 || c > 6 || c % 2 != 0 || d < 0 || d > 6 || d % 2 != 0 { return -1 }
		eu[i], ev[i], uv[i], vu[i] = int(ru), int(rv), c, d
	}
	scale := scales[rounds]
	mut lambda, labels_m, labels_n := [max_n]i64{}, [max_n]i64{}, [max_n]i64{}
	mut agreement := false
	mut dual_scaled := i64(0)
	for iteration in 1 .. rounds + 1 {
		energy_m := dd_solve(0,n,m,owner,source_cap,sink_cap,eu,ev,uv,vu,lambda,scale,mut labels_m)
		energy_n := dd_solve(1,n,m,owner,source_cap,sink_cap,eu,ev,uv,vu,lambda,scale,mut labels_n)
		dual_scaled = energy_m + energy_n
		agreement = true
		for u in 0 .. n { if owner[u] == 2 && labels_m[u] != labels_n[u] { agreement = false } }
		if agreement || iteration == rounds { break }
		step := scale / i64(iteration)
		for u in 0 .. n { if owner[u] == 2 { lambda[u] += step * (labels_m[u] - labels_n[u]) } }
	}
	return 2 * (dual_scaled + offset) + if agreement { 1 } else { 0 }
}
