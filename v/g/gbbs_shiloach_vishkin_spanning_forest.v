// Clean-room bounded GBBS Shiloach-Vishkin spanning-forest profile.
const gbbs_sv_forest_n = 12
const gbbs_sv_forest_m = 24
const gbbs_sv_forest_input = 50

fn find_root(mut parent []int, vertex_in int) int {
	mut vertex := vertex_in
	for parent[vertex] != vertex {
		parent[vertex] = parent[parent[vertex]]
		vertex = parent[vertex]
	}
	return vertex
}

@[export: 'gbbs_shiloach_vishkin_spanning_forest']
pub fn gbbs_shiloach_vishkin_spanning_forest(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > gbbs_sv_forest_input { return -1 }
		n64 := input[0]
		m64 := input[1]
		if n64 < 1 || n64 > gbbs_sv_forest_n || m64 < 0 || m64 > gbbs_sv_forest_m ||
			length != usize(2 + 2*m64) { return -1 }
		n := int(n64)
		m := int(m64)
		mut seen := [][]bool{len: gbbs_sv_forest_n, init: []bool{len: gbbs_sv_forest_n, init: false}}
		mut edge_u := []int{len: gbbs_sv_forest_m, init: 0}
		mut edge_v := []int{len: gbbs_sv_forest_m, init: 0}
		for edge in 0 .. m {
			u64 := input[2 + 2*edge]
			v64 := input[3 + 2*edge]
			if u64 < 0 || u64 >= n64 || v64 <= u64 || v64 >= n64 { return -1 }
			u := int(u64)
			v := int(v64)
			if seen[u][v] { return -1 }
			seen[u][v] = true
			edge_u[edge] = u
			edge_v[edge] = v
		}
		if output == nil || capacity < usize(m) { return -2 }
		mut parent := []int{len: gbbs_sv_forest_n, init: 0}
		mut previous := []int{len: gbbs_sv_forest_n, init: 0}
		mut next_parent := []int{len: gbbs_sv_forest_n, init: 0}
		mut best_lower := []int{len: gbbs_sv_forest_n, init: 0}
		mut selected := []u8{len: gbbs_sv_forest_m, init: 0}
		for vertex in 0 .. n { parent[vertex] = vertex }
		for _round in 0 .. n {
			for vertex in 0 .. n {
				previous[vertex] = find_root(mut parent, vertex)
				next_parent[vertex] = previous[vertex]
				best_lower[vertex] = n
			}
			for edge in 0 .. m {
				root_u := previous[edge_u[edge]]
				root_v := previous[edge_v[edge]]
				if root_u == root_v { continue }
				lower := min(root_u, root_v)
				higher := max(root_u, root_v)
				if previous[higher] == higher && lower < best_lower[higher] { best_lower[higher] = lower }
			}
			mut changed := false
			for higher in 0 .. n {
				lower := best_lower[higher]
				if lower == n { continue }
				next_parent[higher] = lower
				changed = true
				for edge in 0 .. m {
					root_u := previous[edge_u[edge]]
					root_v := previous[edge_v[edge]]
					if (root_u == higher && root_v == lower) || (root_u == lower && root_v == higher) {
						selected[edge] = 1
						break
					}
				}
			}
			for vertex in 0 .. n { parent[vertex] = find_root(mut next_parent, vertex) }
			if !changed { break }
		}
		for edge in 0 .. m { output[edge] = selected[edge] }
		return i64(m)
	}
}
