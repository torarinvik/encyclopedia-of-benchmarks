package second_best_mst

import "core:c"

MAX_N :: 8
MAX_M :: 20

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
second_best_mst :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 2 + 3 * MAX_M do return -1
	n_value, m_value := input[0], input[1]
	if n_value < 1 || n_value > i64(MAX_N) || m_value < n_value - 1 || m_value > i64(MAX_M) do return -1
	n, m := int(n_value), int(m_value)
	if length != c.size_t(2 + 3 * m) do return -1

	edge_u: [MAX_M]int
	edge_v: [MAX_M]int
	edge_weight: [MAX_M]i64
	order: [MAX_M]int
	seen: [MAX_N][MAX_N]bool = {}
	for edge := 0; edge < m; edge += 1 {
		u_value, v_value := input[2 + 3 * edge], input[3 + 3 * edge]
		weight := input[4 + 3 * edge]
		if u_value < 0 || u_value >= v_value || v_value >= n_value || weight < 0 || weight > 1000000 do return -1
		u, v := int(u_value), int(v_value)
		if seen[u][v] do return -1
		seen[u][v] = true
		edge_u[edge], edge_v[edge], edge_weight[edge], order[edge] = u, v, weight, edge
	}

	for i := 1; i < m; i += 1 {
		edge := order[i]
		j := i
		for j > 0 && (edge_weight[order[j - 1]] > edge_weight[edge] ||
			(edge_weight[order[j - 1]] == edge_weight[edge] && order[j - 1] > edge)) {
			order[j] = order[j - 1]
			j -= 1
		}
		order[j] = edge
	}

	dsu: [MAX_N]int
	component_size: [MAX_N]int
	for vertex := 0; vertex < n; vertex += 1 { dsu[vertex], component_size[vertex] = vertex, 1 }
	in_mst: [MAX_M]bool = {}
	tree_to: [MAX_N][MAX_N]int = {}
	tree_edge: [MAX_N][MAX_N]int = {}
	degree: [MAX_N]int = {}
	selected := 0
	mst_weight: i64 = 0
	for position := 0; position < m; position += 1 {
		edge := order[position]
		root_u, root_v := edge_u[edge], edge_v[edge]
		for dsu[root_u] != root_u { dsu[root_u] = dsu[dsu[root_u]]; root_u = dsu[root_u] }
		for dsu[root_v] != root_v { dsu[root_v] = dsu[dsu[root_v]]; root_v = dsu[root_v] }
		if root_u == root_v do continue
		if component_size[root_u] < component_size[root_v] { root_u, root_v = root_v, root_u }
		dsu[root_v] = root_u
		component_size[root_u] += component_size[root_v]
		in_mst[edge] = true
		selected += 1
		mst_weight += edge_weight[edge]
		tree_to[edge_u[edge]][degree[edge_u[edge]]] = edge_v[edge]
		tree_edge[edge_u[edge]][degree[edge_u[edge]]] = edge
		degree[edge_u[edge]] += 1
		tree_to[edge_v[edge]][degree[edge_v[edge]]] = edge_u[edge]
		tree_edge[edge_v[edge]][degree[edge_v[edge]]] = edge
		degree[edge_v[edge]] += 1
	}
	if selected != n - 1 do return -1

	second_weight: i64 = -1
	entering_edge, leaving_edge := -1, -1
	for added := 0; added < m; added += 1 {
		if in_mst[added] do continue
		parent: [MAX_N]int
		parent_edge: [MAX_N]int
		queue: [MAX_N]int
		for vertex := 0; vertex < n; vertex += 1 { parent[vertex] = -1 }
		head, tail := 0, 0
		start, target := edge_u[added], edge_v[added]
		parent[start] = start
		queue[tail] = start
		tail += 1
		for head < tail && parent[target] == -1 {
			vertex := queue[head]
			head += 1
			for i := 0; i < degree[vertex]; i += 1 {
				next := tree_to[vertex][i]
				if parent[next] != -1 do continue
				parent[next], parent_edge[next] = vertex, tree_edge[vertex][i]
				queue[tail] = next
				tail += 1
			}
		}
		first_weight, second_path_weight: i64 = -1, -1
		first_edge, second_path_edge := -1, -1
		vertex := target
		for vertex != start {
			path_edge := parent_edge[vertex]
			weight := edge_weight[path_edge]
			if weight > first_weight {
				second_path_weight, second_path_edge = first_weight, first_edge
				first_weight, first_edge = weight, path_edge
			} else if weight == first_weight {
				if first_edge < 0 || path_edge < first_edge do first_edge = path_edge
			} else if weight > second_path_weight {
				second_path_weight, second_path_edge = weight, path_edge
			} else if weight == second_path_weight && (second_path_edge < 0 || path_edge < second_path_edge) {
				second_path_edge = path_edge
			}
			vertex = parent[vertex]
		}
		removed_weight: i64 = -1
		removed_edge := -1
		if edge_weight[added] > first_weight {
			removed_weight, removed_edge = first_weight, first_edge
		} else if edge_weight[added] == first_weight && second_path_weight >= 0 {
			removed_weight, removed_edge = second_path_weight, second_path_edge
		}
		if removed_edge < 0 do continue
		candidate := mst_weight + edge_weight[added] - removed_weight
		if second_weight < 0 || candidate < second_weight ||
			(candidate == second_weight && (added < entering_edge || (added == entering_edge && removed_edge < leaving_edge))) {
			second_weight = candidate
			entering_edge, leaving_edge = added, removed_edge
		}
	}

	if output == nil || capacity < 32 do return -2
	store_i64_le(output, 0, mst_weight)
	store_i64_le(output, 8, second_weight)
	store_i64_le(output, 16, i64(entering_edge))
	store_i64_le(output, 24, i64(leaving_edge))
	return 32
}
