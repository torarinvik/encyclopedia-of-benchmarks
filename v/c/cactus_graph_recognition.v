module cactus_graph_recognition

const max_n = 32
const max_m = 128
const max_input = 259
const max_arcs = 256

@[export: 'cactus_graph_recognition']
pub fn cactus_graph_recognition(input &i64, length usize) i64 {
	if length < 2 || length > max_input || unsafe { input == nil } { return -1 }
	unsafe {
		n_value, m_value := input[0], input[1]
		if n_value < 1 || n_value > max_n || m_value < 0 || m_value > max_m { return -1 }
		n, m := int(n_value), int(m_value)
		if length != usize(2+2*m) { return -1 }

		mut edge_seen := [1024]bool{}
		mut head := [32]int{}
		for u in 0 .. n { head[u] = -1 }
		mut arc_to := [256]int{}
		mut arc_edge := [256]int{}
		mut next_arc := [256]int{}
		mut arc_count := 0
		for e in 0 .. m {
			u_value, v_value := input[2+2*e], input[3+2*e]
			if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value { return -1 }
			u, v := int(u_value), int(v_value)
			if edge_seen[u*max_n+v] { return -1 }
			edge_seen[u*max_n+v] = true
			edge_seen[v*max_n+u] = true
			arc_to[arc_count] = v
			arc_edge[arc_count] = e
			next_arc[arc_count] = head[u]
			head[u] = arc_count
			arc_count++
			arc_to[arc_count] = u
			arc_edge[arc_count] = e
			next_arc[arc_count] = head[v]
			head[v] = arc_count
			arc_count++
		}

		mut state := [32]int{}
		mut parent := [32]int{}
		mut parent_edge := [32]int{}
		mut depth := [32]int{}
		mut cursor := [32]int{}
		mut stack := [32]int{}
		mut cycle_of := [128]int{}
		mut used := [128]bool{}
		mut cycle_vertices := [32]int{}
		for u in 0 .. n {
			parent[u] = -1
			parent_edge[u] = -1
			cursor[u] = -1
		}
		for e in 0 .. m { cycle_of[e] = -1 }
		mut cycles := 0
		mut edge_cactus := true
		mut vertex_cactus := true
		for root in 0 .. n {
			if !edge_cactus { break }
			if state[root] != 0 { continue }
			mut top := 1
			state[root] = 1
			cursor[root] = head[root]
			stack[0] = root
			for top > 0 && edge_cactus {
				u := stack[top-1]
				arc := cursor[u]
				if arc < 0 { state[u] = 2; top--; continue }
				cursor[u] = next_arc[arc]
				e := arc_edge[arc]
				if used[e] { continue }
				used[e] = true
				v := arc_to[arc]
				if state[v] == 0 {
					parent[v] = u
					parent_edge[v] = e
					depth[v] = depth[u] + 1
					state[v] = 1
					cursor[v] = head[v]
					stack[top] = v
					top++
				} else if state[v] == 1 && depth[v] < depth[u] {
					mut x := u
					for x != v {
						tree_edge := parent_edge[x]
						if tree_edge < 0 || cycle_of[tree_edge] != -1 { edge_cactus = false; break }
						x = parent[x]
					}
					if !edge_cactus { break }
					x = u
					cycle_vertices[x]++
					if cycle_vertices[x] > 1 { vertex_cactus = false }
					for x != v {
						tree_edge := parent_edge[x]
						cycle_of[tree_edge] = cycles
						x = parent[x]
						cycle_vertices[x]++
						if cycle_vertices[x] > 1 { vertex_cactus = false }
					}
					cycle_of[e] = cycles
					cycles++
				}
			}
		}
		if !edge_cactus { return 0 }
		result := 4 * cycles + 1
		if vertex_cactus { result += 2 }
		return i64(result)
	}
}
