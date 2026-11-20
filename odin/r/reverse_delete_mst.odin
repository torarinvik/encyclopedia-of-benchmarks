package reverse_delete_mst

import "core:c"

MAX_N :: 8
MAX_M :: 20
MAX_INPUT :: 63

Edge :: struct { u, v, weight: i32 }

graph_connected :: proc(n, m: int, edges: [MAX_M]Edge, active: u64) -> bool {
	seen: [MAX_N]bool
	queue: [MAX_N]int
	head, tail := 0, 1
	seen[0] = true
	queue[0] = 0
	for head < tail {
		vertex := queue[head]
		head += 1
		for id := 0; id < m; id += 1 {
			if ((active >> id) & 1) == 0 do continue
			neighbor := -1
			if int(edges[id].u) == vertex { neighbor = int(edges[id].v) }
			else if int(edges[id].v) == vertex { neighbor = int(edges[id].u) }
			if neighbor >= 0 && !seen[neighbor] {
				seen[neighbor] = true
				queue[tail] = neighbor
				tail += 1
			}
		}
	}
	for vertex := 0; vertex < n; vertex += 1 { if !seen[vertex] do return false }
	return true
}

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

@(export)
reverse_delete_mst :: proc "c" (input: [^]i64, length: c.size_t,
								 output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT) do return -1
	n_word, m_word := input[0], input[1]
	if n_word < 2 || n_word > MAX_N || m_word < n_word - 1 || m_word > MAX_M do return -1
	n, m := int(n_word), int(m_word)
	if length != c.size_t(2 + 3*m) do return -1
	var edges: [MAX_M]Edge
	var order: [MAX_M]int
	for id := 0; id < m; id += 1 {
		u, v, weight := input[2+3*id], input[3+3*id], input[4+3*id]
		if u < 0 || u >= n_word || v < 0 || v >= n_word || u == v || weight < 0 || weight > 1000 do return -1
		edges[id] = Edge{i32(u), i32(v), i32(weight)}
		order[id] = id
		low, high := min(u,v), max(u,v)
		for prior := 0; prior < id; prior += 1 {
			prior_low, prior_high := min(i64(edges[prior].u), i64(edges[prior].v)), max(i64(edges[prior].u), i64(edges[prior].v))
			if low == prior_low && high == prior_high do return -1
		}
	}
	for i := 1; i < m; i += 1 {
		item := order[i]
		j := i
		for j > 0 && (edges[order[j-1]].weight < edges[item].weight ||
			(edges[order[j-1]].weight == edges[item].weight && order[j-1] < item)) {
			order[j] = order[j-1]
			j -= 1
		}
		order[j] = item
	}
	active := (u64(1) << m) - 1
	if !graph_connected(n, m, edges, active) do return -1
	for position := 0; position < m; position += 1 {
		candidate := active & ~(u64(1) << order[position])
		if graph_connected(n, m, edges, candidate) { active = candidate }
	}
	total_weight: i64 = 0
	for id := 0; id < m; id += 1 { if ((active >> id) & 1) != 0 { total_weight += i64(edges[id].weight) } }
	if output == nil || capacity < 16 do return -2
	store_i64_le(output, 0, i64(active))
	store_i64_le(output, 8, total_weight)
	return 16
}
