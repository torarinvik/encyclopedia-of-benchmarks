// Clean-room bounded GBBS Charikar profile; see package LICENSE.txt.
module gbbs_charikar_densest_subgraph

const max_n = 16
const max_m = 64
const invalid_result = -1e300

@[export: 'gbbs_charikar_densest_subgraph']
pub fn gbbs_charikar_densest_subgraph(input &i64, length usize) f64 {
	unsafe {
		if input == nil || length < 2 || length > 130 { return invalid_result }
		n64 := input[0]
		m64 := input[1]
		if n64 < 1 || n64 > max_n || m64 < 0 || m64 > max_m || length != usize(2 + 2 * m64) { return invalid_result }
		n := int(n64)
		m := int(m64)
		mut adjacent := [][]bool{len: max_n, init: []bool{len: max_n, init: false}}
		mut degree := []int{len: max_n, init: 0}
		for edge in 0 .. m {
			u64 := input[2 + 2 * edge]
			v64 := input[3 + 2 * edge]
			if u64 < 0 || u64 >= v64 || v64 >= n64 { return invalid_result }
			u := int(u64)
			v := int(v64)
			if adjacent[u][v] { return invalid_result }
			adjacent[u][v] = true
			adjacent[v][u] = true
			degree[u]++
			degree[v]++
		}
		mut alive := []bool{len: max_n, init: false}
		mut order := []int{len: max_n, init: 0}
		mut position := []int{len: max_n, init: 0}
		for v in 0 .. n { alive[v] = true }
		mut used := 0
		for used < n {
			mut level := max_m
			for v in 0 .. n { if alive[v] && degree[v] < level { level = degree[v] } }
			for {
				mut shell := []int{len: max_n, init: 0}
				mut count := 0
				for v in 0 .. n { if alive[v] && degree[v] == level { shell[count] = v; count++ } }
				if count == 0 { break }
				for i in 0 .. count { alive[shell[i]] = false; order[used] = shell[i]; used++ }
				for v in 0 .. n { if alive[v] {
					mut removed := 0
					for i in 0 .. count { if adjacent[v][shell[i]] { removed++ } }
					next_degree := degree[v] - removed
					degree[v] = if next_degree < level { level } else { next_degree }
				} }
			}
		}
		for i in 0 .. n { position[order[i]] = i }
		mut best := 0.0
		for start in 0 .. n {
			mut edges := 0
			for u in 0 .. n { if position[u] >= start { for v in u + 1 .. n {
				if position[v] >= start && adjacent[u][v] { edges++ }
			} } }
			score := 2.0 * f64(edges) / f64(n - start)
			if score > best { best = score }
		}
		if !best.is_finite() { return invalid_result }
		return best
	}
}
