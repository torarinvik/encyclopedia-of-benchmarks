package gomory_hu_tree
import "core:c"

flow :: proc "contextless" (cap: [^]i64, n, source, sink: int, reachable: [^]bool) -> i64 {
	residual: [64]i64
	for i := 0; i < n*n; i += 1 { residual[i] = cap[i] }
	total: i64
	parent: [8]int
	queue: [8]int
	for {
		for i := 0; i < n; i += 1 { parent[i] = -1 }
		parent[source] = source; head := 0; tail := 1; queue[0] = source
		for head < tail && parent[sink] < 0 { u := queue[head]; head += 1; for v := 0; v < n; v += 1 { if residual[u*n+v] > 0 && parent[v] < 0 { parent[v] = u; if v == sink do break; queue[tail] = v; tail += 1 } } }
		if parent[sink] < 0 do break
		amount := i64(2147483647); v := sink
		for v != source { u := parent[v]; if residual[u*n+v] < amount do amount = residual[u*n+v]; v = u }
		v = sink; for v != source { u := parent[v]; residual[u*n+v] -= amount; residual[v*n+u] += amount; v = u }; total += amount
	}
	for i := 0; i < n; i += 1 { reachable[i] = false }
	head := 0; tail := 1; queue[0] = source; reachable[source] = true
	for head < tail { u := queue[head]; head += 1; for v := 0; v < n; v += 1 { if !reachable[v] && residual[u*n+v] > 0 { reachable[v] = true; queue[tail] = v; tail += 1 } } }
	return total
}

@(export)
gomory_hu_tree :: proc "c" (a: [^]i64, length: c.size_t) -> i64 {
	if a == nil || length < 2 || length > 65 do return -1
	n64 := a[0]; if n64 < 1 || n64 > 8 || length != c.size_t(1+n64*n64) do return -1
	n := int(n64); cap: [64]i64
	for i := 0; i < n*n; i += 1 { if a[1+i] < 0 || a[1+i] > 1000 do return -1; cap[i] = a[1+i] }
	for i := 0; i < n; i += 1 { for j := 0; j < n; j += 1 { if i == j { if cap[i*n+j] != 0 do return -1 } else if cap[i*n+j] != cap[j*n+i] do return -1 } }
	parent: [8]int; weight: [8]i64
	for s := 1; s < n; s += 1 { t := parent[s]; reachable: [8]bool; f := flow(&cap[0], n, s, t, &reachable[0]); weight[s] = f
		for v := 0; v < n; v += 1 { if v != s && parent[v] == t && reachable[v] do parent[v] = s }
		if t != 0 && reachable[parent[t]] { parent[s] = parent[t]; parent[t] = s; weight[s] = weight[t]; weight[t] = f }
	}
	pair: [64]i64
	for source := 0; source < n; source += 1 { prev: [8]int; q: [8]int; for i := 0; i < n; i += 1 { prev[i] = -2 }; head := 0; tail := 1; q[0] = source; prev[source] = -1
		for head < tail { u := q[head]; head += 1; for v := 0; v < n; v += 1 { if v != u && ((v > 0 && parent[v] == u) || (u > 0 && parent[u] == v)) && prev[v] == -2 { prev[v] = u; q[tail] = v; tail += 1 } } }
		for target := 0; target < n; target += 1 { if target != source { x := target; minimum := i64(2147483647); for x != source { p := prev[x]; edge := p; if x > 0 && parent[x] == p do edge = x; if weight[edge] < minimum do minimum = weight[edge]; x = p }; pair[source*n+target] = minimum } }
	}
	h := u64(14695981039346656037); for i := 0; i < n*n; i += 1 { bits := transmute(u64)pair[i]; for k := 0; k < 8; k += 1 { h = (h ~ (bits & 255)) * 1099511628211; bits >>= 8 } }; return transmute(i64)h
}
