// Clean-room bounded GBBS BKV12 profile; see package LICENSE.txt.
module gbbs_bkv12_densest_subgraph

const max_n = 16
const max_m = 64
const max_input = 132
const invalid_result = -1e300

@[export: 'gbbs_bkv12_densest_subgraph']
pub fn gbbs_bkv12_densest_subgraph(input &i64, length usize) f64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return invalid_result }
		n64 := input[0]
		m64 := input[1]
		if n64 < 1 || n64 > max_n || m64 < 0 || m64 > max_m || length != usize(2 + 2*m64) { return invalid_result }
		n := int(n64)
		m := int(m64)
		mut adjacent := [][]bool{len: max_n, init: []bool{len: max_n, init: false}}
		mut degree := []i64{len: max_n, init: 0}
		mut edge_u := []int{len: max_m, init: 0}
		mut edge_v := []int{len: max_m, init: 0}
		for edge in 0 .. m {
			u64 := input[2 + 2*edge]
			v64 := input[3 + 2*edge]
			if u64 < 0 || u64 >= v64 || v64 >= n64 { return invalid_result }
			u := int(u64)
			v := int(v64)
			if adjacent[u][v] { return invalid_result }
			adjacent[u][v] = true
			adjacent[v][u] = true
			degree[u]++
			degree[v]++
			edge_u[edge] = u
			edge_v[edge] = v
		}
		mut alive := []bool{len: max_n, init: false}
		for vertex in 0 .. n { alive[vertex] = true }
		mut remaining := n
		mut best := 0.0
		for remaining > 0 {
			mut total := i64(0)
			for vertex in 0 .. n { if alive[vertex] { total += degree[vertex] } }
			density := f64(total) / f64(remaining)
			if density > best { best = density }
			mut removed := []bool{len: max_n, init: false}
			mut count := 0
			for vertex in 0 .. n {
				if alive[vertex] && 1000*degree[vertex]*i64(remaining) <= 1001*total {
					removed[vertex] = true
					count++
				}
			}
			if count == 0 { return invalid_result }
			for vertex in 0 .. n { if removed[vertex] { alive[vertex] = false } }
			remaining -= count
			for edge in 0 .. m {
				u := edge_u[edge]
				v := edge_v[edge]
				if removed[u] && alive[v] { degree[v]-- }
				if removed[v] && alive[u] { degree[u]-- }
			}
		}
		return best
	}
}
