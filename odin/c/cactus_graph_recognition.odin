package cactus_graph_recognition

import "core:c"

MAX_N :: 32
MAX_M :: 128
MAX_INPUT :: 259
MAX_ARCS :: 256

@(export)
cactus_graph_recognition :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	n_value, m_value := input[0], input[1]
	if n_value < 1 || n_value > MAX_N || m_value < 0 || m_value > MAX_M do return -1
	n, m := int(n_value), int(m_value)
	if int(length) != 2 + 2*m do return -1

	edge_seen: [1024]bool = false
	head: [32]int = 0
	for u := 0; u < n; u += 1 { head[u] = -1 }
	arc_to, arc_edge, next_arc: [256]int = 0
	arc_count := 0
	for e := 0; e < m; e += 1 {
		u_value, v_value := input[2+2*e], input[3+2*e]
		if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value do return -1
		u, v := int(u_value), int(v_value)
		if edge_seen[u*MAX_N+v] do return -1
		edge_seen[u*MAX_N+v], edge_seen[v*MAX_N+u] = true, true
		arc_to[arc_count], arc_edge[arc_count] = v, e
		next_arc[arc_count], head[u] = head[u], arc_count
		arc_count += 1
		arc_to[arc_count], arc_edge[arc_count] = u, e
		next_arc[arc_count], head[v] = head[v], arc_count
		arc_count += 1
	}

	state: [32]int = 0
	parent, parent_edge, depth, cursor, stack, cycle_vertices: [32]int = 0
	cycle_of: [128]int = 0
	used: [128]bool = false
	for u := 0; u < n; u += 1 { parent[u], parent_edge[u], cursor[u] = -1, -1, -1 }
	for e := 0; e < m; e += 1 { cycle_of[e] = -1 }
	cycles := 0
	edge_cactus, vertex_cactus := true, true

	for root := 0; root < n; root += 1 {
		if !edge_cactus do break
		if state[root] != 0 do continue
		top := 1
		state[root], cursor[root], stack[0] = 1, head[root], root
		for top > 0 && edge_cactus {
			u := stack[top-1]
			arc := cursor[u]
			if arc < 0 { state[u] = 2; top -= 1; continue }
			cursor[u] = next_arc[arc]
			e := arc_edge[arc]
			if used[e] do continue
			used[e] = true
			v := arc_to[arc]
			if state[v] == 0 {
				parent[v], parent_edge[v], depth[v] = u, e, depth[u]+1
				state[v], cursor[v] = 1, head[v]
				stack[top] = v
				top += 1
			} else if state[v] == 1 && depth[v] < depth[u] {
				x := u
				for x != v {
					tree_edge := parent_edge[x]
					if tree_edge < 0 || cycle_of[tree_edge] != -1 { edge_cactus = false; break }
					x = parent[x]
				}
				if !edge_cactus do break
				x = u
				cycle_vertices[x] += 1
				if cycle_vertices[x] > 1 do vertex_cactus = false
				for x != v {
					tree_edge := parent_edge[x]
					cycle_of[tree_edge] = cycles
					x = parent[x]
					cycle_vertices[x] += 1
					if cycle_vertices[x] > 1 do vertex_cactus = false
				}
				cycle_of[e] = cycles
				cycles += 1
			}
		}
	}
	if !edge_cactus do return 0
	return i64(4*cycles + (if vertex_cactus do 2 else 0) + 1)
}
