module second_best_mst

const max_n = 8
const max_m = 20

fn find_root(mut parent []int, start int) int {
	mut vertex := start
	for parent[vertex] != vertex {
		parent[vertex] = parent[parent[vertex]]
		vertex = parent[vertex]
	}
	return vertex
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'second_best_mst']
pub fn second_best_mst(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > usize(2 + 3 * max_m) { return -1 }
	n_value := unsafe { input[0] }
	m_value := unsafe { input[1] }
	if n_value < 1 || n_value > max_n || m_value < n_value - 1 || m_value > max_m { return -1 }
	n := int(n_value)
	m := int(m_value)
	if length != usize(2 + 3 * m) { return -1 }

	mut edge_u := []int{len: max_m}
	mut edge_v := []int{len: max_m}
	mut edge_weight := []i64{len: max_m}
	mut order := []int{len: max_m}
	mut seen := []bool{len: max_n * max_n}
	for edge in 0 .. m {
		u_value := unsafe { input[2 + 3 * edge] }
		v_value := unsafe { input[3 + 3 * edge] }
		weight := unsafe { input[4 + 3 * edge] }
		if u_value < 0 || u_value >= v_value || v_value >= n_value || weight < 0 || weight > 1_000_000 { return -1 }
		u, v := int(u_value), int(v_value)
		if seen[u * max_n + v] { return -1 }
		seen[u * max_n + v] = true
		edge_u[edge], edge_v[edge], edge_weight[edge], order[edge] = u, v, weight, edge
	}

	for i in 1 .. m {
	edge := order[i]
		mut j := i
		for j > 0 && (edge_weight[order[j - 1]] > edge_weight[edge] ||
			(edge_weight[order[j - 1]] == edge_weight[edge] && order[j - 1] > edge)) {
			order[j] = order[j - 1]
			j--
		}
		order[j] = edge
	}

	mut dsu := []int{len: max_n}
	mut component_size := []int{len: max_n}
	for vertex in 0 .. n { dsu[vertex], component_size[vertex] = vertex, 1 }
	mut in_mst := []bool{len: max_m}
	mut tree_to := []int{len: max_n * max_n}
	mut tree_edge := []int{len: max_n * max_n}
	mut degree := []int{len: max_n}
	mut selected := 0
	mut mst_weight := i64(0)
	for position in 0 .. m {
		edge := order[position]
		mut root_u, root_v := edge_u[edge], edge_v[edge]
		for dsu[root_u] != root_u { dsu[root_u] = dsu[dsu[root_u]]; root_u = dsu[root_u] }
		for dsu[root_v] != root_v { dsu[root_v] = dsu[dsu[root_v]]; root_v = dsu[root_v] }
		if root_u == root_v { continue }
		if component_size[root_u] < component_size[root_v] { root_u, root_v = root_v, root_u }
		dsu[root_v] = root_u
		component_size[root_u] += component_size[root_v]
		in_mst[edge] = true
		selected++
		mst_weight += edge_weight[edge]
		cell_u := edge_u[edge] * max_n + degree[edge_u[edge]]
		tree_to[cell_u], tree_edge[cell_u] = edge_v[edge], edge
		degree[edge_u[edge]]++
		cell_v := edge_v[edge] * max_n + degree[edge_v[edge]]
		tree_to[cell_v], tree_edge[cell_v] = edge_u[edge], edge
		degree[edge_v[edge]]++
	}
	if selected != n - 1 { return -1 }

	mut second_weight := i64(-1)
	mut entering_edge, leaving_edge := -1, -1
	for added in 0 .. m {
		if in_mst[added] { continue }
		mut parent := []int{len: max_n, init: -1}
		mut parent_edge := []int{len: max_n}
		mut queue := []int{len: max_n}
		mut head, tail := 0, 0
		start, target := edge_u[added], edge_v[added]
		parent[start] = start
		queue[tail] = start
		tail++
		for head < tail && parent[target] == -1 {
			vertex := queue[head]
			head++
			for i in 0 .. degree[vertex] {
				cell := vertex * max_n + i
				next := tree_to[cell]
				if parent[next] != -1 { continue }
				parent[next], parent_edge[next] = vertex, tree_edge[cell]
				queue[tail] = next
				tail++
			}
		}
		mut first_weight, second_path_weight := i64(-1), i64(-1)
		mut first_edge, second_path_edge := -1, -1
		mut vertex := target
		for vertex != start {
			path_edge := parent_edge[vertex]
			weight := edge_weight[path_edge]
			if weight > first_weight {
				second_path_weight, second_path_edge = first_weight, first_edge
				first_weight, first_edge = weight, path_edge
			} else if weight == first_weight {
				if first_edge < 0 || path_edge < first_edge { first_edge = path_edge }
			} else if weight > second_path_weight {
				second_path_weight, second_path_edge = weight, path_edge
			} else if weight == second_path_weight && (second_path_edge < 0 || path_edge < second_path_edge) {
				second_path_edge = path_edge
			}
			vertex = parent[vertex]
		}
		mut removed_weight := i64(-1)
		mut removed_edge := -1
		if edge_weight[added] > first_weight {
			removed_weight, removed_edge = first_weight, first_edge
		} else if edge_weight[added] == first_weight && second_path_weight >= 0 {
			removed_weight, removed_edge = second_path_weight, second_path_edge
		}
		if removed_edge < 0 { continue }
		candidate := mst_weight + edge_weight[added] - removed_weight
		if second_weight < 0 || candidate < second_weight ||
			(candidate == second_weight && (added < entering_edge || (added == entering_edge && removed_edge < leaving_edge))) {
			second_weight = candidate
			entering_edge, leaving_edge = added, removed_edge
		}
	}

	if unsafe { output == nil } || capacity < 32 { return -2 }
	store_i64_le(mut output, 0, mst_weight)
	store_i64_le(mut output, 8, second_weight)
	store_i64_le(mut output, 16, i64(entering_edge))
	store_i64_le(mut output, 24, i64(leaving_edge))
	return 32
}
