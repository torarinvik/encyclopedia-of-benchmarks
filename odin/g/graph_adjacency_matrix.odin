package graph_adjacency_matrix

import "core:c"

MAX_VERTICES :: 8
MAX_VERTEX_ID_EXCLUSIVE :: 32
MAX_EDGES :: 64
MAX_OPERATIONS :: 24

vertex_index :: proc "contextless" (vertices: ^[MAX_VERTICES]int, count, value: int) -> int {
	for i := 0; i < count; i += 1 {
		if vertices[i] == value do return i
	}
	return -1
}

remove_vertex :: proc "contextless" (vertices: ^[MAX_VERTICES]int, matrix: ^[MAX_VERTICES*MAX_VERTICES]int, count: ^int, index: int) {
	old_count := count^
	for row := index; row + 1 < old_count; row += 1 {
		vertices[row] = vertices[row+1]
		for column := 0; column < old_count; column += 1 {
			matrix[row*MAX_VERTICES+column] = matrix[(row+1)*MAX_VERTICES+column]
		}
	}
	for row := 0; row + 1 < old_count; row += 1 {
		for column := index; column + 1 < old_count; column += 1 {
			matrix[row*MAX_VERTICES+column] = matrix[row*MAX_VERTICES+column+1]
		}
	}
	for i := 0; i < old_count; i += 1 {
		matrix[(old_count-1)*MAX_VERTICES+i] = 0
		matrix[i*MAX_VERTICES+old_count-1] = 0
	}
	count^ = old_count - 1
}

put_i64_le :: proc "contextless" (output: [^]u8, word: c.size_t, value: i64) {
	bits := u64(value)
	for byte: c.size_t = 0; byte < 8; byte += 1 {
		output[word*8+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
graph_adjacency_matrix :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 do return -1
	directed_value, vertex_count_value := input[0], input[1]
	if (directed_value != 0 && directed_value != 1) || vertex_count_value < 0 || vertex_count_value > MAX_VERTICES do return -1
	vertex_count := int(vertex_count_value)
	if length < c.size_t(3+vertex_count) do return -1
	vertices: [MAX_VERTICES]int
	matrix: [MAX_VERTICES*MAX_VERTICES]int
	position := 2
	for i := 0; i < vertex_count; i += 1 {
		value := input[position]
		position += 1
		if value < 0 || value >= MAX_VERTEX_ID_EXCLUSIVE || vertex_index(&vertices, i, int(value)) >= 0 do return -1
		vertices[i] = int(value)
	}
	if c.size_t(position) >= length do return -1
	edge_value := input[position]
	position += 1
	if edge_value < 0 || edge_value > MAX_EDGES do return -1
	edge_count := int(edge_value)
	if length < c.size_t(position+2*edge_count+1) do return -1
	for _ := 0; _ < edge_count; _ += 1 {
		source_value, destination_value := input[position], input[position+1]
		position += 2
		if source_value < 0 || source_value >= MAX_VERTEX_ID_EXCLUSIVE || destination_value < 0 || destination_value >= MAX_VERTEX_ID_EXCLUSIVE do return -1
		source := vertex_index(&vertices, vertex_count, int(source_value))
		destination := vertex_index(&vertices, vertex_count, int(destination_value))
		if source < 0 || destination < 0 || matrix[source*MAX_VERTICES+destination] != 0 do return -1
		matrix[source*MAX_VERTICES+destination] = 1
		if directed_value == 0 do matrix[destination*MAX_VERTICES+source] = 1
	}
	operation_value := input[position]
	position += 1
	if operation_value < 0 || operation_value > MAX_OPERATIONS do return -1
	operation_count := int(operation_value)
	if length != c.size_t(position+3*operation_count) do return -1
	results: [MAX_OPERATIONS]int
	for operation_index := 0; operation_index < operation_count; operation_index += 1 {
		operation, a_value, b_value := input[position], input[position+1], input[position+2]
		position += 3
		if operation == 0 {
			if a_value < 0 || a_value >= MAX_VERTEX_ID_EXCLUSIVE || b_value != 0 || vertex_count >= MAX_VERTICES || vertex_index(&vertices, vertex_count, int(a_value)) >= 0 do return -1
			for i := 0; i < MAX_VERTICES; i += 1 { matrix[i*MAX_VERTICES+vertex_count] = 0; matrix[vertex_count*MAX_VERTICES+i] = 0 }
			vertices[vertex_count] = int(a_value)
			vertex_count += 1
			results[operation_index] = 1
		} else if operation == 1 {
			if a_value < 0 || a_value >= MAX_VERTEX_ID_EXCLUSIVE || b_value != 0 do return -1
			removed := vertex_index(&vertices, vertex_count, int(a_value))
			if removed < 0 do return -1
			remove_vertex(&vertices, &matrix, &vertex_count, removed)
			results[operation_index] = 1
		} else if operation == 2 || operation == 3 || operation == 5 {
			if a_value < 0 || a_value >= MAX_VERTEX_ID_EXCLUSIVE || b_value < 0 || b_value >= MAX_VERTEX_ID_EXCLUSIVE do return -1
			source := vertex_index(&vertices, vertex_count, int(a_value))
			destination := vertex_index(&vertices, vertex_count, int(b_value))
			if source < 0 || destination < 0 do return -1
			cell := source*MAX_VERTICES+destination
			present := matrix[cell] != 0
			if operation == 5 {
				if present do results[operation_index] = 1
				else do results[operation_index] = 0
			}
			else if operation == 2 {
				if present do return -1
				matrix[cell] = 1
				if directed_value == 0 do matrix[destination*MAX_VERTICES+source] = 1
				results[operation_index] = 1
			} else {
				if !present do return -1
				matrix[cell] = 0
				if directed_value == 0 do matrix[destination*MAX_VERTICES+source] = 0
				results[operation_index] = 1
			}
		} else if operation == 4 {
			if a_value < 0 || a_value >= MAX_VERTEX_ID_EXCLUSIVE || b_value != 0 do return -1
			if vertex_index(&vertices, vertex_count, int(a_value)) >= 0 do results[operation_index] = 1
			else do results[operation_index] = 0
		} else if operation == 6 {
			if a_value != 0 || b_value != 0 do return -1
			vertex_count = 0
			for i := 0; i < MAX_VERTICES*MAX_VERTICES; i += 1 { matrix[i] = 0 }
			results[operation_index] = 1
		} else do return -1
	}

	words := c.size_t(2+operation_count+vertex_count+vertex_count*vertex_count)
	if output == nil || capacity < words*8 do return -2
	word: c.size_t = 0
	put_i64_le(output, word, i64(operation_count)); word += 1
	for i := 0; i < operation_count; i += 1 { put_i64_le(output, word, i64(results[i])); word += 1 }
	put_i64_le(output, word, i64(vertex_count)); word += 1
	for i := 0; i < vertex_count; i += 1 { put_i64_le(output, word, i64(vertices[i])); word += 1 }
	for row := 0; row < vertex_count; row += 1 {
		for column := 0; column < vertex_count; column += 1 {
			put_i64_le(output, word, i64(matrix[row*MAX_VERTICES+column]))
			word += 1
		}
	}
	return i64(words*8)
}
