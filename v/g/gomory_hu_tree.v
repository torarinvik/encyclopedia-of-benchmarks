module gomory_hu_tree

fn flow(cap []i64, n int, source int, sink int, mut reachable [8]bool) i64 {
	mut residual := [64]i64{}
	for i in 0 .. n * n { residual[i] = cap[i] }
	mut total := i64(0)
	for {
		mut parent := [8]int{}
	for i in 0 .. n { parent[i] = -1 }
		parent[source] = source
	mut queue := [8]int{}
	mut head := 0
	mut tail := 1
	queue[0] = source
		for head < tail && parent[sink] < 0 {
			u := queue[head]; head++
			for v in 0 .. n { if residual[u * n + v] > 0 && parent[v] < 0 { parent[v] = u; if v == sink { break }; queue[tail] = v; tail++ } }
		}
		if parent[sink] < 0 { break }
		mut amount := i64(2147483647)
		mut v := sink
		for v != source { u := parent[v]; if residual[u * n + v] < amount { amount = residual[u * n + v] }; v = u }
		v = sink
		for v != source { u := parent[v]; residual[u * n + v] -= amount; residual[v * n + u] += amount; v = u }
		total += amount
	}
	mut q := [8]int{}
	mut head := 0
	mut tail := 1
	q[0] = source
	reachable[source] = true
	for head < tail { u := q[head]; head++; for v in 0 .. n { if !reachable[v] && residual[u * n + v] > 0 { reachable[v] = true; q[tail] = v; tail++ } } }
	return total
}

@[export: 'gomory_hu_tree']
pub fn gomory_hu_tree(a &i64, length usize) i64 {
	if isnil(a) || length < 2 || length > 65 { return -1 }
	n64 := unsafe { a[0] }
	if n64 < 1 || n64 > 8 || length != usize(1 + n64 * n64) { return -1 }
	n := int(n64)
	mut cap := [64]i64{}
	for i in 0 .. n * n { x := unsafe { a[1 + i] }; if x < 0 || x > 1000 { return -1 }; cap[i] = x }
	for i in 0 .. n { for j in 0 .. n { if cap[i * n + j] != (if i == j { i64(0) } else { cap[j * n + i] }) { return -1 } } }
	mut parent := [8]int{}
	mut weight := [8]i64{}
	for s in 1 .. n { t := parent[s]; mut reach := [8]bool{}; f := flow(cap[..], n, s, t, mut reach); weight[s] = f
		for v in 0 .. n { if v != s && parent[v] == t && reach[v] { parent[v] = s } }
		if t != 0 && reach[parent[t]] { parent[s] = parent[t]; parent[t] = s; weight[s] = weight[t]; weight[t] = f }
	}
	mut pair := [64]i64{}
	for source in 0 .. n { mut prev := [8]int{}; for i in 0 .. n { prev[i] = -2 }; mut q := [8]int{}; mut head := 0; mut tail := 1; q[0] = source; prev[source] = -1
		for head < tail { u := q[head]; head++; for v in 0 .. n { if v != u && ((v > 0 && parent[v] == u) || (u > 0 && parent[u] == v)) && prev[v] == -2 { prev[v] = u; q[tail] = v; tail++ } } }
		for target in 0 .. n { if target != source { mut x := target; mut minimum := i64(2147483647); for x != source { p := prev[x]; mut edge := p; if x > 0 && parent[x] == p { edge = x }; if weight[edge] < minimum { minimum = weight[edge] }; x = p }; pair[source * n + target] = minimum } }
	}
	mut h := u64(14695981039346656037)
	for i in 0 .. n * n { mut bits := u64(pair[i]); for _ in 0 .. 8 { h = (h ^ (bits & 255)) * u64(1099511628211); bits >>= 8 } }
	return i64(h)
}
