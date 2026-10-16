module graph_adjacency_matrix

const max_vertices = 8
const max_vertex_id_exclusive = 32
const max_edges = 64
const max_operations = 24

fn vertex_index(vertices [max_vertices]int, count int, value int) int {
	for i in 0 .. count { if vertices[i] == value { return i } }
	return -1
}

fn remove_vertex(mut vertices [max_vertices]int, mut matrix [max_vertices * max_vertices]int, mut count int, index int) {
	old_count := count
	for row in index .. old_count - 1 {
		vertices[row] = vertices[row + 1]
		for column in 0 .. old_count { matrix[row * max_vertices + column] = matrix[(row + 1) * max_vertices + column] }
	}
	for row in 0 .. old_count - 1 {
		for column in index .. old_count - 1 { matrix[row * max_vertices + column] = matrix[row * max_vertices + column + 1] }
	}
	for i in 0 .. old_count {
		matrix[(old_count - 1) * max_vertices + i] = 0
		matrix[i * max_vertices + old_count - 1] = 0
	}
	count = old_count - 1
}

fn put_i64_le(output &u8, word usize, value i64) {
	bits := u64(value)
	unsafe {
		for byte in 0 .. 8 { output[word * 8 + usize(byte)] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'graph_adjacency_matrix']
pub fn graph_adjacency_matrix(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 4 { return -1 }
	unsafe {
		directed := input[0]
		count_value := input[1]
		if (directed != 0 && directed != 1) || count_value < 0 || count_value > max_vertices || length < usize(3 + count_value) { return -1 }
		mut count := int(count_value)
		mut vertices := [max_vertices]int{}
		mut matrix := [max_vertices * max_vertices]int{}
		mut position := 2
		for i in 0 .. count {
			value := input[position]
			position++
			if value < 0 || value >= max_vertex_id_exclusive || vertex_index(vertices, i, int(value)) >= 0 { return -1 }
			vertices[i] = int(value)
		}
		if usize(position) >= length { return -1 }
		edge_value := input[position]
		position++
		if edge_value < 0 || edge_value > max_edges || length < usize(position + 2 * edge_value + 1) { return -1 }
		for _ in 0 .. int(edge_value) {
			source_value := input[position]
			destination_value := input[position + 1]
			position += 2
			if source_value < 0 || source_value >= max_vertex_id_exclusive || destination_value < 0 || destination_value >= max_vertex_id_exclusive { return -1 }
			source := vertex_index(vertices, count, int(source_value))
			destination := vertex_index(vertices, count, int(destination_value))
			if source < 0 || destination < 0 || matrix[source * max_vertices + destination] != 0 { return -1 }
			matrix[source * max_vertices + destination] = 1
			if directed == 0 { matrix[destination * max_vertices + source] = 1 }
		}
		operation_value := input[position]
		position++
		if operation_value < 0 || operation_value > max_operations || length != usize(position + 3 * operation_value) { return -1 }
		operation_count := int(operation_value)
		mut results := [max_operations]int{}
		for operation_index in 0 .. operation_count {
			operation := input[position]
			a_value := input[position + 1]
			b_value := input[position + 2]
			position += 3
			if operation == 0 {
				if a_value < 0 || a_value >= max_vertex_id_exclusive || b_value != 0 || count >= max_vertices || vertex_index(vertices, count, int(a_value)) >= 0 { return -1 }
				for i in 0 .. max_vertices { matrix[i * max_vertices + count] = 0; matrix[count * max_vertices + i] = 0 }
				vertices[count] = int(a_value)
				count++
				results[operation_index] = 1
			} else if operation == 1 {
				if a_value < 0 || a_value >= max_vertex_id_exclusive || b_value != 0 { return -1 }
				removed := vertex_index(vertices, count, int(a_value))
				if removed < 0 { return -1 }
				remove_vertex(mut vertices, mut matrix, mut count, removed)
				results[operation_index] = 1
			} else if operation == 2 || operation == 3 || operation == 5 {
				if a_value < 0 || a_value >= max_vertex_id_exclusive || b_value < 0 || b_value >= max_vertex_id_exclusive { return -1 }
				source := vertex_index(vertices, count, int(a_value))
				destination := vertex_index(vertices, count, int(b_value))
				if source < 0 || destination < 0 { return -1 }
				cell := source * max_vertices + destination
				present := matrix[cell] != 0
				if operation == 5 { if present { results[operation_index] = 1 } } else if operation == 2 {
					if present { return -1 }
					matrix[cell] = 1
					if directed == 0 { matrix[destination * max_vertices + source] = 1 }
					results[operation_index] = 1
				} else {
					if !present { return -1 }
					matrix[cell] = 0
					if directed == 0 { matrix[destination * max_vertices + source] = 0 }
					results[operation_index] = 1
				}
			} else if operation == 4 {
				if a_value < 0 || a_value >= max_vertex_id_exclusive || b_value != 0 { return -1 }
				if vertex_index(vertices, count, int(a_value)) >= 0 { results[operation_index] = 1 }
			} else if operation == 6 {
				if a_value != 0 || b_value != 0 { return -1 }
				count = 0
				for i in 0 .. max_vertices * max_vertices { matrix[i] = 0 }
				results[operation_index] = 1
			} else { return -1 }
		}
		words := 2 + operation_count + count + count * count
		if unsafe { output == nil } || capacity < usize(words * 8) { return -2 }
		mut word := 0
		put_i64_le(output, usize(word), i64(operation_count)); word++
		for i in 0 .. operation_count { put_i64_le(output, usize(word), i64(results[i])); word++ }
		put_i64_le(output, usize(word), i64(count)); word++
		for i in 0 .. count { put_i64_le(output, usize(word), i64(vertices[i])); word++ }
		for row in 0 .. count {
			for column in 0 .. count { put_i64_le(output, usize(word), i64(matrix[row * max_vertices + column])); word++ }
		}
		return i64(words * 8)
	}
}
