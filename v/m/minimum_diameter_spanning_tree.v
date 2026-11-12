module minimum_diameter_spanning_tree

const max_n = 8
const max_m = 20
const max_input_values = 2 + 3 * max_m + 1
const inf = i64(1_000_000_000_000)

fn shortest_tree(n int, m int, edge_u []int, edge_v []int, edge_weight []i64,
	center_kind int, center_root int, center_x2 i64, center_edge int,
	mut distance []i64, mut parent_edge []i64) {
	mut settled := []bool{len: max_n}
	for vertex in 0 .. n {
		distance[vertex] = inf
		parent_edge[vertex] = -1
	}
	if center_kind == 0 {
		distance[center_root] = 0
	} else {
		mut u := edge_u[center_edge]
		mut v := edge_v[center_edge]
		if u > v {
			u, v = v, u
		}
		distance[u] = center_x2
		distance[v] = 2 * edge_weight[center_edge] - center_x2
	}
	for _ in 0 .. n {
		mut current := n
		for vertex in 0 .. n {
			if !settled[vertex] && (current == n || distance[vertex] < distance[current]) {
				current = vertex
			}
		}
		if current == n || distance[current] == inf {
			return
		}
		settled[current] = true
		for edge_id in 0 .. m {
			left := edge_u[edge_id]
			right := edge_v[edge_id]
			if left == right {
				continue
			}
			mut neighbor := n
			if current == left {
				neighbor = right
			} else if current == right {
				neighbor = left
			} else {
				continue
			}
			candidate := distance[current] + 2 * edge_weight[edge_id]
			if !settled[neighbor] && candidate < distance[neighbor] {
				distance[neighbor] = candidate
				parent_edge[neighbor] = i64(edge_id)
			}
		}
	}
}

fn selected_tree_diameter(n int, selected []int, edge_u []int, edge_v []int,
	edge_weight []i64) i64 {
	mut adjacent := []bool{len: max_n * max_n}
	mut weight := []i64{len: max_n * max_n}
	for index in 0 .. n - 1 {
		edge_id := selected[index]
		u := edge_u[edge_id]
		v := edge_v[edge_id]
		adjacent[u * max_n + v] = true
		adjacent[v * max_n + u] = true
		weight[u * max_n + v] = edge_weight[edge_id]
		weight[v * max_n + u] = edge_weight[edge_id]
	}
	mut diameter := i64(0)
	for source in 0 .. n {
		mut distance := []i64{len: max_n, init: -1}
		mut parent := []int{len: max_n, init: n}
		mut stack := []int{len: max_n}
		mut top := 1
		stack[0] = source
		distance[source] = 0
		for top > 0 {
			top--
			current := stack[top]
			if distance[current] > diameter {
				diameter = distance[current]
			}
			for neighbor in 0 .. n {
				cell := current * max_n + neighbor
				if adjacent[cell] && parent[current] != neighbor && distance[neighbor] < 0 {
					parent[neighbor] = current
					distance[neighbor] = distance[current] + weight[cell]
					stack[top] = neighbor
					top++
				}
			}
		}
	}
	return diameter
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

@[export: 'minimum_diameter_spanning_tree']
pub fn minimum_diameter_spanning_tree(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_values {
		return -1
	}
	n_value := unsafe { input[0] }
	m_value := unsafe { input[1] }
	if n_value < 1 || n_value > max_n || m_value < 0 || m_value > max_m {
		return -1
	}
	n := int(n_value)
	m := int(m_value)
	if length != usize(2 + 3 * m) {
		return -1
	}

	mut edge_u := []int{len: max_m}
	mut edge_v := []int{len: max_m}
	mut edge_weight := []i64{len: max_m}
	mut graph_distance := []i64{len: max_n * max_n, init: inf}
	for vertex in 0 .. n {
		graph_distance[vertex * max_n + vertex] = 0
	}
	for edge_id in 0 .. m {
		offset := 2 + 3 * edge_id
		u_value := unsafe { input[offset] }
		v_value := unsafe { input[offset + 1] }
		edge_w := unsafe { input[offset + 2] }
		if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value ||
			edge_w < 0 || edge_w > 9 {
			return -1
		}
		u := int(u_value)
		v := int(v_value)
		edge_u[edge_id] = u
		edge_v[edge_id] = v
		edge_weight[edge_id] = edge_w
		if u != v && edge_w < graph_distance[u * max_n + v] {
			graph_distance[u * max_n + v] = edge_w
			graph_distance[v * max_n + u] = edge_w
		}
	}
	for middle in 0 .. n {
		for left in 0 .. n {
			for right in 0 .. n {
				cell := left * max_n + right
				candidate := graph_distance[left * max_n + middle] + graph_distance[middle * max_n + right]
				if candidate < graph_distance[cell] {
					graph_distance[cell] = candidate
				}
			}
		}
	}
	for vertex in 0 .. n {
		if graph_distance[vertex] == inf {
			return -1
		}
	}

	mut best_radius2 := inf
	mut best_kind := 0
	mut best_root := 0
	mut best_edge := 0
	mut best_x2 := i64(0)
	for root in 0 .. n {
		mut eccentricity := i64(0)
		for vertex in 0 .. n {
			if graph_distance[root * max_n + vertex] > eccentricity {
				eccentricity = graph_distance[root * max_n + vertex]
			}
		}
		radius2 := 2 * eccentricity
		if radius2 < best_radius2 {
			best_radius2 = radius2
			best_kind = 0
			best_root = root
		}
	}
	for edge_id in 0 .. m {
		mut u := edge_u[edge_id]
		mut v := edge_v[edge_id]
		edge_w := edge_weight[edge_id]
		if u == v {
			continue
		}
		if u > v {
			u, v = v, u
		}
		for x2 in 0 .. int(2 * edge_w + 1) {
			mut radius2 := i64(0)
			for vertex in 0 .. n {
				from_u := 2 * graph_distance[u * max_n + vertex] + i64(x2)
				from_v := 2 * graph_distance[v * max_n + vertex] + 2 * edge_w - i64(x2)
				value := if from_u < from_v { from_u } else { from_v }
				if value > radius2 {
					radius2 = value
				}
			}
			if radius2 < best_radius2 {
				best_radius2 = radius2
				best_kind = 1
				best_root = u
				best_x2 = i64(x2)
				best_edge = edge_id
			}
		}
	}

	mut center_distance := []i64{len: max_n}
	mut parent_edge := []i64{len: max_n}
	shortest_tree(n, m, edge_u, edge_v, edge_weight, best_kind, best_root,
		best_x2, best_edge, mut center_distance, mut parent_edge)
	mut selected := []int{len: max_n}
	mut selected_count := 0
	for vertex in 0 .. n {
		if parent_edge[vertex] >= 0 {
			selected[selected_count] = int(parent_edge[vertex])
			selected_count++
		}
	}
	if selected_count + 2 == n && best_kind == 1 {
		u := edge_u[best_edge]
		v := edge_v[best_edge]
		if parent_edge[u] == -1 && parent_edge[v] == -1 {
			selected[selected_count] = best_edge
			selected_count++
		}
	}
	if selected_count != n - 1 {
		return -1
	}
	for left in 0 .. selected_count {
		for right in left + 1 .. selected_count {
			if selected[right] < selected[left] {
				selected[left], selected[right] = selected[right], selected[left]
			}
		}
	}

	mut staged := []i64{len: max_n}
	staged[0] = selected_tree_diameter(n, selected, edge_u, edge_v, edge_weight)
	for index in 0 .. selected_count {
		staged[index + 1] = i64(selected[index])
	}
	required := 8 * n
	if unsafe { output == nil } || capacity < usize(required) {
		return -2
	}
	for index in 0 .. n {
		store_i64_le(mut output, 8 * index, staged[index])
	}
	return i64(required)
}
