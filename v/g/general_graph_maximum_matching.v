// Deterministic Edmonds blossom maximum-cardinality matching, n <= 12.
const ggm_n_max = 12
const ggm_input_max = 134

fn ggm_lca(match []int, parent []int, base []int, a0 int, b0 int) int {
	mut seen := []bool{len: ggm_n_max, init: false}
	mut a := a0
	mut b := b0
	for {
		a = base[a]
		seen[a] = true
		if match[a] < 0 { break }
		a = parent[match[a]]
	}
	for {
		b = base[b]
		if seen[b] { return b }
		b = parent[match[b]]
	}
}

fn ggm_mark_path(mut match []int, mut parent []int, base []int, mut blossom []bool, v0 int, root int, child0 int) {
	mut v := v0
	mut child := child0
	for base[v] != root {
		blossom[base[v]] = true
		blossom[base[match[v]]] = true
		parent[v] = child
		child = match[v]
		v = parent[match[v]]
	}
}

fn ggm_find_path(n int, adj [][]bool, mut matching []int, mut parent []int, mut base []int, root int) bool {
	mut used := []bool{len: ggm_n_max, init: false}
	mut queue := []int{len: ggm_n_max, init: 0}
	mut head := 0
	mut tail := 0
	for i in 0 .. n { parent[i] = -1; base[i] = i }
	queue[tail] = root
	tail++
	used[root] = true
	for head < tail {
		v := queue[head]
		head++
		for u in 0 .. n {
			if !adj[v][u] || base[v] == base[u] || matching[v] == u { continue }
			if u == root || (matching[u] >= 0 && parent[matching[u]] >= 0) {
				cur := ggm_lca(matching, parent, base, v, u)
				mut blossom := []bool{len: ggm_n_max, init: false}
				ggm_mark_path(mut matching, mut parent, base, mut blossom, v, cur, u)
				ggm_mark_path(mut matching, mut parent, base, mut blossom, u, cur, v)
				for i in 0 .. n {
					if blossom[base[i]] {
						base[i] = cur
						if !used[i] { used[i] = true; queue[tail] = i; tail++ }
					}
				}
			} else if parent[u] < 0 {
				parent[u] = v
				if matching[u] < 0 {
					mut x := u
					for x >= 0 {
						pv := parent[x]
						next := if pv >= 0 { matching[pv] } else { -1 }
						if pv >= 0 { matching[x] = pv; matching[pv] = x }
						x = next
					}
					return true
				}
				mate := matching[u]
				used[mate] = true
				queue[tail] = mate
				tail++
			}
		}
	}
	return false
}

fn ggm_put_i64(mut output &u8, value i64) {
	bits := u64(value)
	for i in 0 .. 8 { unsafe { output[i] = u8((bits >> (8 * i)) & 255) } }
}

@[export: 'general_graph_maximum_matching']
pub fn general_graph_maximum_matching(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > ggm_input_max { return -1 }
		n64 := input[0]
		m64 := input[1]
		if n64 < 2 || n64 > ggm_n_max || m64 < 0 || m64 > n64 * (n64 - 1) / 2 || length != usize(2 + 2 * m64) { return -1 }
		n := int(n64)
		m := int(m64)
		mut adj := [][]bool{len: ggm_n_max, init: []bool{len: ggm_n_max, init: false}}
		for e in 0 .. m {
			u64 := input[2 + 2 * e]
			v64 := input[3 + 2 * e]
			if u64 < 0 || v64 <= u64 || v64 >= n64 { return -1 }
			u := int(u64); v := int(v64)
			if adj[u][v] { return -1 }
			adj[u][v] = true; adj[v][u] = true
		}
		mut matching := []int{len: ggm_n_max, init: -1}
		mut parent := []int{len: ggm_n_max, init: -1}
		mut base := []int{len: ggm_n_max, init: 0}
		for i in 0 .. n { if matching[i] < 0 { _ = ggm_find_path(n, adj, mut matching, mut parent, mut base, i) } }
		mut cardinality := i64(0)
		for i in 0 .. n { if matching[i] > i { cardinality++ } }
		if output == nil || capacity < 8 { return -2 }
		ggm_put_i64(mut output, cardinality)
		return 8
	}
}
