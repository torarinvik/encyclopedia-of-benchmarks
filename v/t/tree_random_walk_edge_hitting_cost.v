module tree_random_walk_edge_hitting_cost

const max_n = 16
const max_edges = max_n - 1
const max_arcs = 2 * max_edges
const max_input_length = 48

fn tree_random_walk_edge_hitting_cost_find(mut sets [max_n]i32, vertex_value int) int {
	mut vertex := vertex_value
	for sets[vertex] != i32(vertex) {
		sets[vertex] = sets[sets[vertex]]
		vertex = int(sets[vertex])
	}
	return vertex
}

fn tree_random_walk_edge_hitting_cost_store(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'tree_random_walk_edge_hitting_cost']
pub fn tree_random_walk_edge_hitting_cost(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input_length { return -1 }
		n_value, root_value := input[0], input[1]
		if n_value < 1 || n_value > max_n || root_value < 0 || root_value >= n_value { return -1 }
		n, root := int(n_value), int(root_value)
		edge_count := n - 1
		if length != usize(2 + 3 * edge_count) { return -1 }

		mut head := [max_n]i32{}
		mut to := [max_arcs]i32{}
		mut next_arc := [max_arcs]i32{}
		mut sets := [max_n]i32{}
		mut input_u := [max_edges]int{}
		mut input_v := [max_edges]int{}
		mut incident_sum := [max_n]i64{}
		mut down := [max_n]i64{}
		mut up := [max_n]i64{}
		for vertex in 0 .. n {
			head[vertex] = -1
			sets[vertex] = i32(vertex)
		}
		mut arc_count := 0
		for edge in 0 .. edge_count {
			offset := 2 + 3 * edge
			u_value, v_value, weight := input[offset], input[offset + 1], input[offset + 2]
			if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value
				|| u_value == v_value || weight < 1 || weight > 9 { return -1 }
			u, v := int(u_value), int(v_value)
			set_u := tree_random_walk_edge_hitting_cost_find(mut sets, u)
			set_v := tree_random_walk_edge_hitting_cost_find(mut sets, v)
			if set_u == set_v { return -1 }
			sets[set_v] = i32(set_u)
			input_u[edge], input_v[edge] = u, v
			to[arc_count] = i32(v)
			next_arc[arc_count] = head[u]
			head[u] = i32(arc_count)
			arc_count++
			to[arc_count] = i32(u)
			next_arc[arc_count] = head[v]
			head[v] = i32(arc_count)
			arc_count++
			incident_sum[u] += weight
			incident_sum[v] += weight
		}

		output_bytes := 16 * edge_count
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut parent := [max_n]i32{}
		mut order := [max_n]int{}
		for vertex in 0 .. n { parent[vertex] = -1 }
		parent[root] = i32(root)
		order[0] = root
		mut order_size := 1
		mut cursor := 0
		for cursor < order_size {
			vertex := order[cursor]
			mut arc := head[vertex]
			for arc >= 0 {
				index := int(arc)
				neighbor := int(to[index])
				if parent[neighbor] == -1 {
					parent[neighbor] = i32(vertex)
					order[order_size] = neighbor
					order_size++
				}
				arc = next_arc[index]
			}
			cursor++
		}
		for position := n - 1; position >= 0; position-- {
			vertex := order[position]
			down[vertex] = incident_sum[vertex]
			mut arc := head[vertex]
			for arc >= 0 {
				index := int(arc)
				child := int(to[index])
				if parent[child] == i32(vertex) { down[vertex] += down[child] }
				arc = next_arc[index]
			}
		}
		for position in 0 .. n {
			vertex := order[position]
			mut arc := head[vertex]
			for arc >= 0 {
				index := int(arc)
				child := int(to[index])
				if parent[child] == i32(vertex) {
					up[child] = up[vertex] + down[vertex] - down[child]
				}
				arc = next_arc[index]
			}
		}
		for edge in 0 .. edge_count {
			u, v := input_u[edge], input_v[edge]
			mut toward_v, toward_u := i64(0), i64(0)
			if parent[u] == i32(v) {
				toward_v, toward_u = down[u], up[u]
			} else {
				toward_v, toward_u = up[v], down[v]
			}
			tree_random_walk_edge_hitting_cost_store(mut output, 16 * edge, toward_v)
			tree_random_walk_edge_hitting_cost_store(mut output, 16 * edge + 8, toward_u)
		}
		return i64(output_bytes)
	}
}
