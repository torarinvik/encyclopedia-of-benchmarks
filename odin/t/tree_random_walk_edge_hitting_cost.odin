package tree_random_walk_edge_hitting_cost

import "core:c"

MAX_N :: 16
MAX_EDGES :: MAX_N - 1
MAX_ARCS :: 2 * MAX_EDGES
MAX_INPUT_LENGTH :: 48

store_i64_le :: proc "contextless" (output: [^]u8, offset: c.size_t, value: i64) {
	bits := u64(value)
	for byte := c.size_t(0); byte < 8; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
tree_random_walk_edge_hitting_cost :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) { return -1 }
	n_value, root_value := input[0], input[1]
	if n_value < 1 || n_value > MAX_N || root_value < 0 || root_value >= n_value { return -1 }
	n, root := int(n_value), int(root_value)
	edge_count := n - 1
	if length != c.size_t(2 + 3*edge_count) { return -1 }

	head := [MAX_N]i64{}
	to := [MAX_ARCS]i64{}
	next_arc := [MAX_ARCS]i64{}
	sets := [MAX_N]i64{}
	input_u := [MAX_EDGES]i64{}
	input_v := [MAX_EDGES]i64{}
	incident_sum := [MAX_N]i64{}
	down := [MAX_N]i64{}
	up := [MAX_N]i64{}
	for vertex := 0; vertex < n; vertex += 1 {
		head[vertex] = -1
		sets[vertex] = i64(vertex)
	}
	arc_count := 0
	for edge := 0; edge < edge_count; edge += 1 {
		offset := 2 + 3*edge
		u_value, v_value, weight := input[offset], input[offset+1], input[offset+2]
		if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value
			|| u_value == v_value || weight < 1 || weight > 9 { return -1 }
		u, v := int(u_value), int(v_value)
		set_u, set_v := u, v
		for sets[set_u] != i64(set_u) {
			sets[set_u] = sets[int(sets[set_u])]
			set_u = int(sets[set_u])
		}
		for sets[set_v] != i64(set_v) {
			sets[set_v] = sets[int(sets[set_v])]
			set_v = int(sets[set_v])
		}
		if set_u == set_v { return -1 }
		sets[set_v] = i64(set_u)
		input_u[edge], input_v[edge] = i64(u), i64(v)
		to[arc_count] = i64(v)
		next_arc[arc_count] = head[u]
		head[u] = i64(arc_count)
		arc_count += 1
		to[arc_count] = i64(u)
		next_arc[arc_count] = head[v]
		head[v] = i64(arc_count)
		arc_count += 1
		incident_sum[u] += weight
		incident_sum[v] += weight
	}

	output_bytes := c.size_t(16 * edge_count)
	if output == nil || capacity < output_bytes { return -2 }
	parent := [MAX_N]i64{}
	order := [MAX_N]i64{}
	for vertex := 0; vertex < n; vertex += 1 { parent[vertex] = -1 }
	parent[root] = i64(root)
	order[0] = i64(root)
	order_size, cursor := 1, 0
	for cursor < order_size {
		vertex := int(order[cursor])
		arc := head[vertex]
		for arc >= 0 {
			index := int(arc)
			neighbor := int(to[index])
			if parent[neighbor] == -1 {
				parent[neighbor] = i64(vertex)
				order[order_size] = i64(neighbor)
				order_size += 1
			}
			arc = next_arc[index]
		}
		cursor += 1
	}
	for position := n-1; position >= 0; position -= 1 {
		vertex := int(order[position])
		down[vertex] = incident_sum[vertex]
		arc := head[vertex]
		for arc >= 0 {
			index := int(arc)
			child := int(to[index])
			if parent[child] == i64(vertex) { down[vertex] += down[child] }
			arc = next_arc[index]
		}
	}
	for position := 0; position < n; position += 1 {
		vertex := int(order[position])
		arc := head[vertex]
		for arc >= 0 {
			index := int(arc)
			child := int(to[index])
			if parent[child] == i64(vertex) { up[child] = up[vertex] + down[vertex] - down[child] }
			arc = next_arc[index]
		}
	}
	for edge := 0; edge < edge_count; edge += 1 {
		u, v := int(input_u[edge]), int(input_v[edge])
		toward_v, toward_u := i64(0), i64(0)
		if parent[u] == i64(v) { toward_v, toward_u = down[u], up[u] }
		else { toward_v, toward_u = up[v], down[v] }
		store_i64_le(output, c.size_t(16*edge), toward_v)
		store_i64_le(output, c.size_t(16*edge+8), toward_u)
	}
	return i64(output_bytes)
}
