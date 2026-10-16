module edmonds_blossom_algorithm

const max_v = 20

@[export: 'edmonds_blossom_algorithm']
pub fn edmonds_blossom_algorithm(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 { return -1 }
	n64 := unsafe { input[0] }; m64 := unsafe { input[1] }
	if n64 < 0 || n64 > max_v || m64 < 0 || m64 > 190 || length != usize(2 + 2 * m64) { return -1 }
	n := int(n64); m := int(m64)
	mut graph := [max_v * max_v]bool{}
	for i in 0 .. m {
		a := unsafe { input[2 + 2 * i] }; b := unsafe { input[3 + 2 * i] }
		if a < 0 || b < 0 || a >= n64 || b >= n64 || a == b { return -1 }
		u := int(a); v := int(b); graph[u * max_v + v] = true; graph[v * max_v + u] = true
	}
	mut mate := [max_v]int{}; mut parent := [max_v]int{}; mut base := [max_v]int{}; mut queue := [max_v]int{}
	mut used := [max_v]bool{}; mut blossom := [max_v]bool{}
	for i in 0 .. max_v { mate[i] = -1 }
	mut answer := 0
	for root in 0 .. n {
		if mate[root] != -1 { continue }
		for i in 0 .. n { used[i] = false; parent[i] = -1; base[i] = i }
		mut head := 0; mut tail := 0; queue[tail] = root; tail++; used[root] = true; mut endpoint := -1
		for head < tail && endpoint == -1 {
			v := queue[head]; head++
			for u in 0 .. n {
				if !graph[v * max_v + u] || base[v] == base[u] || mate[v] == u { continue }
				if u == root || (mate[u] != -1 && parent[mate[u]] != -1) {
					mut path := [max_v]bool{}; mut x := v; mut y := u
					for { x = base[x]; path[x] = true; if mate[x] == -1 { break }; x = parent[mate[x]] }
					for !path[base[y]] { y = parent[mate[base[y]]] }
					common := base[y]; for i in 0 .. n { blossom[i] = false }
					x = v; y = u
					for base[x] != common { blossom[base[x]] = true; blossom[base[mate[x]]] = true; parent[x] = y; y = mate[x]; x = parent[mate[x]] }
					x = u; y = v
					for base[x] != common { blossom[base[x]] = true; blossom[base[mate[x]]] = true; parent[x] = y; y = mate[x]; x = parent[mate[x]] }
					for i in 0 .. n { if blossom[base[i]] { base[i] = common; if !used[i] { used[i] = true; queue[tail] = i; tail++ } } }
				} else if parent[u] == -1 {
					parent[u] = v
					if mate[u] == -1 { endpoint = u; break }
					next := mate[u]; used[next] = true; queue[tail] = next; tail++
				}
			}
		}
		if endpoint != -1 { mut v := endpoint; for v != -1 { pv := parent[v]; next := mate[pv]; mate[v] = pv; mate[pv] = v; v = next }; if mate[root] != -1 { answer++ } }
	}
	return i64(answer)
}
