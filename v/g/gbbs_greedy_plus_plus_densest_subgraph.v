// Clean-room bounded GBBS GreedyPlusPlus profile; see package LICENSE.txt.
module gbbs_greedy_plus_plus_densest_subgraph

const max_n = 16
const max_m = 64
const max_input = 132
const invalid_result = -1e300

@[export: 'gbbs_greedy_plus_plus_densest_subgraph']
pub fn gbbs_greedy_plus_plus_densest_subgraph(input &i64, length usize) f64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return invalid_result }
		n64 := input[0]
		m64 := input[1]
		if n64 < 10 || n64 > max_n || m64 < 0 || m64 > max_m || length != usize(2 + 2*m64) { return invalid_result }
		n := int(n64)
		m := int(m64)
		mut adjacent := [][]bool{len: max_n, init: []bool{len: max_n, init: false}}
		mut load := []i64{len: max_n, init: 0}
		for edge in 0 .. m {
			u64 := input[2 + 2*edge]
			v64 := input[3 + 2*edge]
			if u64 < 0 || u64 >= v64 || v64 >= n64 { return invalid_result }
			u := int(u64)
			v := int(v64)
			if adjacent[u][v] { return invalid_result }
			adjacent[u][v] = true
			adjacent[v][u] = true
			load[u]++
			load[v]++
		}
		mut best := 0.0
		for _round in 0 .. 20 {
			mut degree := []i64{len: max_n, init: 0}
			mut alive := []bool{len: max_n, init: false}
			mut order := []int{len: max_n, init: 0}
			mut position := []int{len: max_n, init: 0}
			for vertex in 0 .. n {
				degree[vertex] = load[vertex]
				alive[vertex] = true
			}
			mut used := 0
			for used < n {
				mut level := i64(0x7fffffffffffffff)
				for vertex in 0 .. n { if alive[vertex] && degree[vertex] < level { level = degree[vertex] } }
				mut shell := []int{len: max_n, init: 0}
				mut count := 0
				for vertex in 0 .. n { if alive[vertex] && degree[vertex] == level { shell[count] = vertex; count++ } }
				for i in 0 .. count { alive[shell[i]] = false; order[used] = shell[i]; used++ }
				for vertex in 0 .. n { if alive[vertex] {
					mut removed := i64(0)
					for i in 0 .. count { if adjacent[vertex][shell[i]] { removed++ } }
					next := degree[vertex] - removed
					degree[vertex] = if next < level { level } else { next }
				} }
			}
			for i in 0 .. n { position[order[i]] = i }
			mut density_above := []i64{len: max_n, init: 0}
			for vertex in 0 .. n {
				mut later := i64(0)
				for other in 0 .. n { if adjacent[vertex][other] && position[other] > position[vertex] { later++ } }
				density_above[position[vertex]] = 2 * later
				load[vertex] += later
			}
			mut suffix_sum := i64(0)
			mut index := n
			for index > 0 {
				index--
				suffix_sum += density_above[index]
				score := f64(suffix_sum) / f64(n - index)
				if score > best { best = score }
			}
		}
		return best
	}
}
