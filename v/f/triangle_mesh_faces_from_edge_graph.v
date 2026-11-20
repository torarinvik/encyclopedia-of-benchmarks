module triangle_mesh_faces_from_edge_graph

const max_vertices = 8
const max_edges = 28
const max_triangles = 56
const max_input_words = 59
const max_output_words = 170

struct FaceTriangle {
	a int
	b int
	c int
	e0 int
	e1 int
	e2 int
	active bool
}

fn select_triangle(chosen int, mut triangles [max_triangles]FaceTriangle,
	triangle_count int, mut incidence [max_edges]int, mut used [max_edges]int,
	mut staged [max_output_words]i64, mut face_count int) {
	t := triangles[chosen]
	triangles[chosen].active = false
	staged[2 + 3 * face_count] = i64(t.a)
	staged[3 + 3 * face_count] = i64(t.b)
	staged[4 + 3 * face_count] = i64(t.c)
	face_count++
	mut saturated := [max_edges]bool{}
	for edge in [t.e0, t.e1, t.e2] {
		incidence[edge]--
		used[edge]++
		if used[edge] == 2 { saturated[edge] = true }
	}
	for other in 0 .. triangle_count {
		if !triangles[other].active { continue }
		candidate := triangles[other]
		if saturated[candidate.e0] || saturated[candidate.e1] || saturated[candidate.e2] {
			triangles[other].active = false
			incidence[candidate.e0]--
			incidence[candidate.e1]--
			incidence[candidate.e2]--
		}
	}
}

fn store_i64_le(output &u8, offset int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'triangle_mesh_faces_from_edge_graph']
pub fn triangle_mesh_faces_from_edge_graph(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input_words { return -1 }
		vertex_word, edge_word := input[0], input[1]
		if vertex_word < 3 || vertex_word > max_vertices || edge_word < 0 || edge_word > max_edges { return -1 }
		vertices, edge_count := int(vertex_word), int(edge_word)
		if edge_count > vertices * (vertices - 1) / 2 || length != usize(2 + 2 * edge_count) { return -1 }

		mut edge_index := [max_vertices][max_vertices]int{init: -1}
		mut vertex_degree := [max_vertices]int{}
		for edge in 0 .. edge_count {
			left_word, right_word := input[2 + 2 * edge], input[3 + 2 * edge]
			if left_word < 0 || left_word >= vertex_word || right_word < 0 || right_word >= vertex_word || left_word == right_word { return -1 }
			mut left, mut right := int(left_word), int(right_word)
			if left > right { left, right = right, left }
			if edge_index[left][right] >= 0 { return -1 }
			edge_index[left][right] = edge
			edge_index[right][left] = edge
			vertex_degree[left]++
			vertex_degree[right]++
		}

		mut triangles := [max_triangles]FaceTriangle{}
		mut triangle_count := 0
		mut incidence := [max_edges]int{}
		for a in 0 .. vertices {
			for b in a + 1 .. vertices {
				for c in b + 1 .. vertices {
					e0, e1, e2 := edge_index[a][b], edge_index[a][c], edge_index[b][c]
					if e0 >= 0 && e1 >= 0 && e2 >= 0 {
						triangles[triangle_count] = FaceTriangle{a: a, b: b, c: c, e0: e0, e1: e1, e2: e2, active: true}
						triangle_count++
						incidence[e0]++
						incidence[e1]++
						incidence[e2]++
					}
				}
			}
		}

		mut used := [max_edges]int{}
		mut staged := [max_output_words]i64{}
		mut face_count := 0
		mut fallback_used := false
		for {
			mut chosen := triangle_count
			for index in 0 .. triangle_count {
				t := triangles[index]
				if t.active && (vertex_degree[t.a] == 3 || vertex_degree[t.b] == 3 || vertex_degree[t.c] == 3) { chosen = index; break }
			}
			if chosen < triangle_count {
				select_triangle(chosen, mut triangles, triangle_count, mut incidence, mut used, mut staged, mut face_count)
				continue
			}

			mut forced := [max_edges]bool{}
			for edge in 0 .. edge_count { forced[edge] = incidence[edge] > 0 && incidence[edge] == 2 - used[edge] }
			chosen = triangle_count
			for index in 0 .. triangle_count {
				t := triangles[index]
				if t.active && (forced[t.e0] || forced[t.e1] || forced[t.e2]) { chosen = index; break }
			}
			if chosen < triangle_count {
				select_triangle(chosen, mut triangles, triangle_count, mut incidence, mut used, mut staged, mut face_count)
				continue
			}

			mut best_score := 3 * max_triangles + 1
			chosen = triangle_count
			for index in 0 .. triangle_count {
				t := triangles[index]
				if !t.active { continue }
				score := incidence[t.e0] + incidence[t.e1] + incidence[t.e2]
				if score < best_score { best_score = score; chosen = index }
			}
			if chosen == triangle_count { break }
			fallback_used = true
			select_triangle(chosen, mut triangles, triangle_count, mut incidence, mut used, mut staged, mut face_count)
		}

		mut complete := edge_count > 0
		for edge in 0 .. edge_count { if used[edge] != 2 { complete = false } }
		staged[0] = i64(if complete { 0 } else { 2 }) + i64(if fallback_used { 1 } else { 0 })
		staged[1] = i64(face_count)
		output_bytes := usize(2 + 3 * face_count) * 8
		if output == nil || capacity < output_bytes { return -2 }
		for word in 0 .. 2 + 3 * face_count { store_i64_le(output, word * 8, staged[word]) }
		return i64(output_bytes)
	}
}
