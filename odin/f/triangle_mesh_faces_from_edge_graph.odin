package triangle_mesh_faces_from_edge_graph

import "core:c"

MAX_VERTICES :: 8
MAX_EDGES :: 28
MAX_TRIANGLES :: 56
MAX_INPUT_WORDS :: 59
MAX_OUTPUT_WORDS :: 170

Triangle :: struct {
	a, b, c: int,
	e0, e1, e2: int,
	active: bool,
}

has_edge :: proc(t: Triangle, edge: int) -> bool {
	return t.e0 == edge || t.e1 == edge || t.e2 == edge
}

select_triangle :: proc(chosen: int, triangles: [^]Triangle, triangle_count: int,
	incidence: [^]int, used: [^]int, staged: [^]i64, face_count: ^int) {
	t := triangles[chosen]
	triangles[chosen].active = false
	staged[2 + 3 * face_count^] = i64(t.a)
	staged[3 + 3 * face_count^] = i64(t.b)
	staged[4 + 3 * face_count^] = i64(t.c)
	face_count^ += 1
	mut_saturated: [MAX_EDGES]bool
	for edge in [3]int{t.e0, t.e1, t.e2} {
		incidence[edge] -= 1
		used[edge] += 1
		if used[edge] == 2 { mut_saturated[edge] = true }
	}
	for other := 0; other < triangle_count; other += 1 {
		if !triangles[other].active do continue
		candidate := triangles[other]
		if mut_saturated[candidate.e0] || mut_saturated[candidate.e1] || mut_saturated[candidate.e2] {
			triangles[other].active = false
			incidence[candidate.e0] -= 1
			incidence[candidate.e1] -= 1
			incidence[candidate.e2] -= 1
		}
	}
}

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

@(export, link_name="triangle_mesh_faces_from_edge_graph")
triangle_mesh_faces_from_edge_graph :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_WORDS) do return -1
	vertex_word, edge_word := input[0], input[1]
	if vertex_word < 3 || vertex_word > MAX_VERTICES || edge_word < 0 || edge_word > MAX_EDGES do return -1
	vertices, edge_count := int(vertex_word), int(edge_word)
	if edge_count > vertices * (vertices - 1) / 2 || length != c.size_t(2 + 2 * edge_count) do return -1

	edge_index: [MAX_VERTICES][MAX_VERTICES]int
	vertex_degree: [MAX_VERTICES]int
	for a := 0; a < MAX_VERTICES; a += 1 {
		for b := 0; b < MAX_VERTICES; b += 1 { edge_index[a][b] = -1 }
	}
	for edge := 0; edge < edge_count; edge += 1 {
		left_word, right_word := input[2 + 2 * edge], input[3 + 2 * edge]
		if left_word < 0 || left_word >= vertex_word || right_word < 0 || right_word >= vertex_word || left_word == right_word do return -1
		left, right := int(left_word), int(right_word)
		if left > right { left, right = right, left }
		if edge_index[left][right] >= 0 do return -1
		edge_index[left][right] = edge
		edge_index[right][left] = edge
		vertex_degree[left] += 1
		vertex_degree[right] += 1
	}

	triangles: [MAX_TRIANGLES]Triangle
	triangle_count := 0
	incidence: [MAX_EDGES]int
	for a := 0; a < vertices; a += 1 {
		for b := a + 1; b < vertices; b += 1 {
			for c := b + 1; c < vertices; c += 1 {
				e0, e1, e2 := edge_index[a][b], edge_index[a][c], edge_index[b][c]
				if e0 >= 0 && e1 >= 0 && e2 >= 0 {
					triangles[triangle_count] = Triangle{a, b, c, e0, e1, e2, true}
					triangle_count += 1
					incidence[e0] += 1
					incidence[e1] += 1
					incidence[e2] += 1
				}
			}
		}
	}

	used: [MAX_EDGES]int
	staged: [MAX_OUTPUT_WORDS]i64
	face_count := 0
	fallback_used := false
	for {
		chosen := triangle_count
		for index := 0; index < triangle_count; index += 1 {
			t := triangles[index]
			if t.active && (vertex_degree[t.a] == 3 || vertex_degree[t.b] == 3 || vertex_degree[t.c] == 3) { chosen = index; break }
		}
		if chosen < triangle_count {
			select_triangle(chosen, &triangles[0], triangle_count, &incidence[0], &used[0], &staged[0], &face_count)
			continue
		}

		forced: [MAX_EDGES]bool
		for edge := 0; edge < edge_count; edge += 1 { forced[edge] = incidence[edge] > 0 && incidence[edge] == 2 - used[edge] }
		chosen = triangle_count
		for index := 0; index < triangle_count; index += 1 {
			t := triangles[index]
			if t.active && (forced[t.e0] || forced[t.e1] || forced[t.e2]) { chosen = index; break }
		}
		if chosen < triangle_count {
			select_triangle(chosen, &triangles[0], triangle_count, &incidence[0], &used[0], &staged[0], &face_count)
			continue
		}

		best_score := 3 * MAX_TRIANGLES + 1
		chosen = triangle_count
		for index := 0; index < triangle_count; index += 1 {
			t := triangles[index]
			if !t.active do continue
			score := incidence[t.e0] + incidence[t.e1] + incidence[t.e2]
			if score < best_score { best_score = score; chosen = index }
		}
		if chosen == triangle_count do break
		fallback_used = true
		select_triangle(chosen, &triangles[0], triangle_count, &incidence[0], &used[0], &staged[0], &face_count)
	}

	complete := edge_count > 0
	for edge := 0; edge < edge_count; edge += 1 { if used[edge] != 2 { complete = false } }
	staged[0] = i64(2)
	if complete { staged[0] = 0 }
	if fallback_used { staged[0] += 1 }
	staged[1] = i64(face_count)
	output_bytes := c.size_t(2 + 3 * face_count) * 8
	if output == nil || capacity < output_bytes do return -2
	for word := 0; word < 2 + 3 * face_count; word += 1 { store_i64_le(output, word * 8, staged[word]) }
	return i64(output_bytes)
}
