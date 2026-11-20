// Clean-room bounded rotation-system planarity recognizer.
package rotation_system_planarity_test

import "core:c"

MAX_N :: 6
MAX_M :: 15
MAX_DARTS :: 30

@(export)
rotation_system_planarity_test :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 33 do return -1
	n64 := input[0]
	m64 := input[1]
	if n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M || length != c.size_t(2 + 2 * m64) do return -1
	n := int(n64)
	m := int(m64)
	adjacent: [MAX_N * MAX_N]bool
	edge_u, edge_v: [MAX_M]int
	for edge := 0; edge < m; edge += 1 {
		u64 := input[2 + 2 * edge]
		v64 := input[3 + 2 * edge]
		if u64 < 0 || u64 >= v64 || v64 >= n64 do return -1
		u := int(u64)
		v := int(v64)
		if adjacent[u * MAX_N + v] do return -1
		adjacent[u * MAX_N + v] = true
		adjacent[v * MAX_N + u] = true
		edge_u[edge] = u
		edge_v[edge] = v
	}
	if n >= 3 && m > 3 * n - 6 do return 0
	edge_id: [MAX_N * MAX_N]int
	for i := 0; i < MAX_N * MAX_N; i += 1 { edge_id[i] = -1 }
	neighbors: [MAX_N * MAX_N]int
	degree: [MAX_N]int
	for edge := 0; edge < m; edge += 1 {
		u := edge_u[edge]
		v := edge_v[edge]
		edge_id[u * MAX_N + v] = edge
		edge_id[v * MAX_N + u] = edge
	}
	for u := 0; u < n; u += 1 { for v := 0; v < n; v += 1 { if adjacent[u * MAX_N + v] {
		neighbors[u * MAX_N + degree[u]] = v
		degree[u] += 1
	} } }
	component: [MAX_N]int
	for v := 0; v < n; v += 1 { component[v] = -1 }
	component_vertices: [MAX_N * MAX_N]int
	component_size: [MAX_N]int
	component_count := 0
	for root := 0; root < n; root += 1 { if component[root] == -1 {
		cid := component_count
		component_count += 1
		queue: [MAX_N]int
		head := 0
		tail := 0
		component[root] = cid
		queue[tail] = root
		tail += 1
		for head < tail {
			here := queue[head]
			head += 1
			component_vertices[cid * MAX_N + component_size[cid]] = here
			component_size[cid] += 1
			for there := 0; there < n; there += 1 { if adjacent[here * MAX_N + there] && component[there] == -1 {
				component[there] = cid
				queue[tail] = there
				tail += 1
			} }
		}
	} }
	for cid := 0; cid < component_count; cid += 1 {
		component_edges := 0
		for edge := 0; edge < m; edge += 1 { if component[edge_u[edge]] == cid { component_edges += 1 } }
		if component_size[cid] >= 3 && component_edges > 3 * component_size[cid] - 6 do return 0
		if component_size[cid] == 1 do continue
		rotation: [MAX_N * MAX_N]int
		for i := 0; i < component_size[cid]; i += 1 {
			vertex := component_vertices[cid * MAX_N + i]
			for j := 0; j < degree[vertex]; j += 1 { rotation[vertex * MAX_N + j] = neighbors[vertex * MAX_N + j] }
		}
		found := false
		done := false
		for !found && !done {
			successor: [MAX_DARTS]int
			for dart := 0; dart < 2 * m; dart += 1 { successor[dart] = -1 }
			for i := 0; i < component_size[cid]; i += 1 {
				vertex := component_vertices[cid * MAX_N + i]
				d := degree[vertex]
				for j := 0; j < d; j += 1 {
					next := (j + 1) % d
					edge := edge_id[vertex * MAX_N + rotation[vertex * MAX_N + j]]
					next_edge := edge_id[vertex * MAX_N + rotation[vertex * MAX_N + next]]
					dart := 2 * edge + (if edge_u[edge] == vertex then 0 else 1)
					next_dart := 2 * next_edge + (if edge_u[next_edge] == vertex then 0 else 1)
					successor[dart] = next_dart
				}
			}
			used: [MAX_DARTS]bool
			faces := 0
			for edge := 0; edge < m; edge += 1 { if component[edge_u[edge]] == cid {
				for orientation := 0; orientation < 2; orientation += 1 {
					dart := 2 * edge + orientation
					if !used[dart] {
						faces += 1
						for !used[dart] { used[dart] = true; dart = successor[dart ^ 1] }
					}
				}
			} }
			if component_size[cid] - component_edges + faces == 2 { found = true } else {
				position := component_size[cid] - 1
				advanced := false
				for position >= 0 && !advanced {
					vertex := component_vertices[cid * MAX_N + position]
					d := degree[vertex]
					pivot := d - 2
					for pivot >= 1 && rotation[vertex * MAX_N + pivot] >= rotation[vertex * MAX_N + pivot + 1] { pivot -= 1 }
					if pivot >= 1 {
						swap_at := d - 1
						for rotation[vertex * MAX_N + swap_at] <= rotation[vertex * MAX_N + pivot] { swap_at -= 1 }
						rotation[vertex * MAX_N + pivot], rotation[vertex * MAX_N + swap_at] = rotation[vertex * MAX_N + swap_at], rotation[vertex * MAX_N + pivot]
						left, right := pivot + 1, d - 1
						for left < right { rotation[vertex * MAX_N + left], rotation[vertex * MAX_N + right] = rotation[vertex * MAX_N + right], rotation[vertex * MAX_N + left]; left += 1; right -= 1 }
						advanced = true
					} else {
						for j := 0; j < d; j += 1 { rotation[vertex * MAX_N + j] = neighbors[vertex * MAX_N + j] }
						position -= 1
					}
				}
				if !advanced { done = true }
			}
		}
		if !found do return 0
	}
	return 1
}
