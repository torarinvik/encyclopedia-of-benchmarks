fn hub_labeling_greedy_ancestor(parent [][]int, source int, ancestor int, target int) bool {
	mut v := target
	for v >= 0 {
		if v == ancestor { return true }
		if v == source { break }
		v = parent[source][v]
	}
	return false
}

fn hub_labeling_greedy_put(mut output &u8, position int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[position + byte] = u8((bits >> u64(byte * 8)) & 255) } }
}

@[export: 'hub_labeling_greedy_order']
pub fn hub_labeling_greedy_order(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 58 { return -1 }
		n0 := input[0]; m0 := input[1]
		if n0 < 1 || n0 > 8 || m0 < 0 || m0 > n0 * (n0 - 1) / 2 || length != usize(2 + 2 * m0) { return -1 }
		n := int(n0); m := int(m0)
		mut adjacent := [][]bool{len: n, init: []bool{len: n, init: false}}
		mut prev_u := i64(-1); mut prev_v := i64(-1)
		for e in 0 .. m {
			u := input[2 + 2 * e]; v := input[3 + 2 * e]
			if u < 0 || v <= u || v >= n0 || (e > 0 && (u < prev_u || (u == prev_u && v <= prev_v))) { return -1 }
			adjacent[int(u)][int(v)] = true; adjacent[int(v)][int(u)] = true; prev_u = u; prev_v = v
		}
		mut parent := [][]int{len: n, init: []int{len: n, init: -1}}
		mut depth := [][]int{len: n, init: []int{len: n, init: -1}}
		mut ways := [][]int{len: n, init: []int{len: n, init: 0}}
		for source in 0 .. n {
			mut queue := []int{len: n, init: 0}; mut head := 0; mut tail := 0
			queue[tail] = source; tail++; depth[source][source] = 0; ways[source][source] = 1
			for head < tail {
				u := queue[head]; head++
				for v in 0 .. n {
					if adjacent[u][v] {
						if depth[source][v] < 0 { depth[source][v] = depth[source][u] + 1; parent[source][v] = u; ways[source][v] = ways[source][u]; queue[tail] = v; tail++ }
						else if depth[source][v] == depth[source][u] + 1 { ways[source][v] += ways[source][u]; if ways[source][v] > 2 { ways[source][v] = 2 } }
					}
				}
			}
			for v in 0 .. n { if depth[source][v] < 0 || ways[source][v] != 1 { return -1 } }
		}
		mut active := [][]bool{len: n, init: []bool{len: n, init: true}}
		mut order := []int{len: n, init: 0}; mut rank := []int{len: n, init: 0}
		for turn in 0 .. n {
			mut counts := []int{len: n, init: 0}
			for source in 0 .. n { for target in 0 .. n { if active[source][target] {
				mut v := target
				for v >= 0 { counts[v]++; if v == source { break }; v = parent[source][v] }
			} } }
			mut best := 0
			for v in 1 .. n { if counts[v] > counts[best] { best = v } }
			order[turn] = best; rank[best] = turn
			for source in 0 .. n { for target in 0 .. n { if active[source][target] && hub_labeling_greedy_ancestor(parent,source,best,target) { active[source][target] = false } } }
		}
		mut has := [][]bool{len: n, init: []bool{len: n, init: false}}
		mut label_dist := [][]int{len: n, init: []int{len: n, init: 0}}
		for u in 0 .. n { for v in u .. n {
			mut path := []int{len: n, init: 0}; mut plen := 0; mut x := v
			for x >= 0 { path[plen] = x; plen++; if x == u { break }; x = parent[u][x] }
			if x < 0 { return -1 }
			mut hub := path[0]; for i in 1 .. plen { if rank[path[i]] < rank[hub] { hub = path[i] } }
			has[u][hub] = true; has[v][hub] = true; label_dist[u][hub] = depth[u][hub]; label_dist[v][hub] = depth[v][hub]
		} }
		mut staged := []i64{len: 81, init: 0}; mut used := 0
		staged[used] = i64(n); used++; for i in 0 .. n { staged[used] = i64(order[i]); used++ }
		for v in 0 .. n {
			mut count := 0; for h in 0 .. n { if has[v][h] { count++ } }
			staged[used] = i64(count); used++
			for h in 0 .. n { if has[v][h] { staged[used] = i64(h | (label_dist[v][h] << 8)); used++ } }
		}
		required := used * 8
		if output == nil || capacity < usize(required) { return -2 }
		for i in 0 .. used { hub_labeling_greedy_put(mut output,i*8,staged[i]) }
		return i64(required)
	}
}
