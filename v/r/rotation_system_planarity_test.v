// Clean-room bounded rotation-system planarity recognizer.
module rotation_system_planarity_test

const max_n = 6
const max_m = 15
const max_darts = 30

@[export: 'rotation_system_planarity_test']
pub fn rotation_system_planarity_test(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 33 { return -1 }
		n64 := input[0]
		m64 := input[1]
		if n64 < 1 || n64 > max_n || m64 < 0 || m64 > max_m || length != usize(2 + 2 * m64) { return -1 }
		n := int(n64)
		m := int(m64)
		mut adjacent := []bool{len: max_n * max_n, init: false}
		mut edge_u := []int{len: max_m, init: 0}
		mut edge_v := []int{len: max_m, init: 0}
		for edge in 0 .. m {
			u64 := input[2 + 2 * edge]
			v64 := input[3 + 2 * edge]
			if u64 < 0 || u64 >= v64 || v64 >= n64 { return -1 }
			u := int(u64)
			v := int(v64)
			if adjacent[u * max_n + v] { return -1 }
			adjacent[u * max_n + v] = true
			adjacent[v * max_n + u] = true
			edge_u[edge] = u
			edge_v[edge] = v
		}
		if n >= 3 && m > 3 * n - 6 { return 0 }
		mut edge_id := []int{len: max_n * max_n, init: -1}
		mut neighbors := []int{len: max_n * max_n, init: 0}
		mut degree := []int{len: max_n, init: 0}
		for edge in 0 .. m {
			u := edge_u[edge]
			v := edge_v[edge]
			edge_id[u * max_n + v] = edge
			edge_id[v * max_n + u] = edge
		}
		for u in 0 .. n { for v in 0 .. n { if adjacent[u * max_n + v] {
			neighbors[u * max_n + degree[u]] = v
			degree[u]++
		} } }
		mut component := []int{len: max_n, init: -1}
		mut component_vertices := []int{len: max_n * max_n, init: 0}
		mut component_size := []int{len: max_n, init: 0}
		mut component_count := 0
		for root in 0 .. n {
			if component[root] == -1 {
				cid := component_count
				component_count++
				mut queue := []int{len: max_n, init: 0}
				mut head := 0
				mut tail := 0
				component[root] = cid
				queue[tail] = root
				tail++
				for head < tail {
					here := queue[head]
					head++
					component_vertices[cid * max_n + component_size[cid]] = here
					component_size[cid]++
					for there in 0 .. n { if adjacent[here * max_n + there] && component[there] == -1 {
						component[there] = cid
						queue[tail] = there
						tail++
					} }
				}
			}
		}
		for cid in 0 .. component_count {
			mut component_edges := 0
			for edge in 0 .. m { if component[edge_u[edge]] == cid { component_edges++ } }
			if component_size[cid] >= 3 && component_edges > 3 * component_size[cid] - 6 { return 0 }
			if component_size[cid] == 1 { continue }
			mut rotation := []int{len: max_n * max_n, init: 0}
			for i in 0 .. component_size[cid] {
				vertex := component_vertices[cid * max_n + i]
				for j in 0 .. degree[vertex] { rotation[vertex * max_n + j] = neighbors[vertex * max_n + j] }
			}
			mut found := false
			mut done := false
			for !found && !done {
				mut successor := []int{len: max_darts, init: -1}
				for i in 0 .. component_size[cid] {
					vertex := component_vertices[cid * max_n + i]
					d := degree[vertex]
					for j in 0 .. d {
						next := (j + 1) % d
						edge := edge_id[vertex * max_n + rotation[vertex * max_n + j]]
						next_edge := edge_id[vertex * max_n + rotation[vertex * max_n + next]]
						dart := 2 * edge
						if edge_u[edge] != vertex { dart++ }
						next_dart := 2 * next_edge
						if edge_u[next_edge] != vertex { next_dart++ }
						successor[dart] = next_dart
					}
				}
				mut used := []bool{len: max_darts, init: false}
				mut faces := 0
				for edge in 0 .. m { if component[edge_u[edge]] == cid {
					for orientation in 0 .. 2 {
						mut dart := 2 * edge + orientation
						if !used[dart] {
							faces++
							for !used[dart] { used[dart] = true; dart = successor[dart ^ 1] }
						}
					}
				} }
				if component_size[cid] - component_edges + faces == 2 { found = true } else {
					mut position := component_size[cid] - 1
					mut advanced := false
					for position >= 0 && !advanced {
						vertex := component_vertices[cid * max_n + position]
						d := degree[vertex]
						mut pivot := d - 2
						for pivot >= 1 && rotation[vertex * max_n + pivot] >= rotation[vertex * max_n + pivot + 1] { pivot-- }
						if pivot >= 1 {
							mut swap_at := d - 1
							for rotation[vertex * max_n + swap_at] <= rotation[vertex * max_n + pivot] { swap_at-- }
							temp := rotation[vertex * max_n + pivot]
							rotation[vertex * max_n + pivot] = rotation[vertex * max_n + swap_at]
							rotation[vertex * max_n + swap_at] = temp
							mut left := pivot + 1
							mut right := d - 1
							for left < right {
								value := rotation[vertex * max_n + left]
								rotation[vertex * max_n + left] = rotation[vertex * max_n + right]
								rotation[vertex * max_n + right] = value
								left++
								right--
							}
							advanced = true
						} else {
						for j in 0 .. d { rotation[vertex * max_n + j] = neighbors[vertex * max_n + j] }
							position--
						}
					}
					if !advanced { done = true }
				}
			}
			if !found { return 0 }
		}
		return 1
	}
}
