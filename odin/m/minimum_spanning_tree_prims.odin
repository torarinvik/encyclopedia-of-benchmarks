package minimum_spanning_tree_prims

import "core:c"

MAX_VERTICES :: 16
MAX_EDGES :: 64
MAX_PARSEABLE_INPUT_LENGTH :: 2 + 3 * MAX_EDGES + 1
MAX_OUTPUT_WORDS :: 1 + 2 * (MAX_VERTICES - 1)
MAX_OUTPUT_BYTES :: 4 * MAX_OUTPUT_WORDS
SOURCE_HEAP_SENTINEL :: i64(9223372036854775807)

top_to_bottom :: proc "contextless" (heap: [^]i64, positions: [^]i32,
	node_position: [^]i32, size, start: int) {
	root := start
	for root*2+1 < size {
		left := root*2+1
		right := left+1
		child := left
		if right < size && heap[right] <= heap[left] do child = right
		if heap[child] >= heap[root] do break
		heap[root], heap[child] = heap[child], heap[root]
		positions[root], positions[child] = positions[child], positions[root]
		node_position[positions[root]] = i32(root)
		node_position[positions[child]] = i32(child)
		root = child
	}
}

decrease_key :: proc "contextless" (value: i64, index_start: int, heap: [^]i64,
	positions: [^]i32, node_position: [^]i32) {
	index := index_start
	vertex := positions[index]
	for index != 0 {
		parent := (index-1)/2
		if value < heap[parent] {
			heap[index] = heap[parent]
			positions[index] = positions[parent]
			node_position[positions[parent]] = i32(index)
		} else {
			heap[index] = value
			positions[index] = vertex
			node_position[vertex] = i32(index)
			return
		}
		index = parent
	}
	heap[0] = value
	positions[0] = vertex
	node_position[vertex] = 0
}

put_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i32) {
	bits := u32(value)
	for byte := 0; byte < 4; byte += 1 {
		output[offset+byte] = u8(bits >> u32(8*byte))
	}
}

@(export)
minimum_spanning_tree_prims :: proc "c" (
	input: [^]i32, length: c.size_t, output: [^]u8, capacity: c.size_t,
) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) do return -1
	raw_vertices, raw_edges := input[0], input[1]
	if raw_vertices < 1 || raw_vertices > MAX_VERTICES || raw_edges < 0 || raw_edges > MAX_EDGES do return -1
	vertex_count, edge_count := int(raw_vertices), int(raw_edges)
	if length != c.size_t(2+3*edge_count) do return -1

	neighbors: [MAX_VERTICES*MAX_VERTICES]i32
	weights: [MAX_VERTICES*MAX_VERTICES]i32
	degree: [MAX_VERTICES]int
	seen: [MAX_VERTICES*MAX_VERTICES]bool
	position := 2
	for index := 0; index < edge_count; index += 1 {
		u, v, weight := input[position], input[position+1], input[position+2]
		position += 3
		if u < 0 || v <= u || v >= raw_vertices do return -1
		edge_index := int(u)*MAX_VERTICES+int(v)
		if seen[edge_index] do return -1
		seen[edge_index] = true
		u_degree := degree[int(u)]
		neighbors[int(u)*MAX_VERTICES+u_degree] = v
		weights[int(u)*MAX_VERTICES+u_degree] = weight
		degree[int(u)] += 1
		v_degree := degree[int(v)]
		neighbors[int(v)*MAX_VERTICES+v_degree] = u
		weights[int(v)*MAX_VERTICES+v_degree] = weight
		degree[int(v)] += 1
	}

	if vertex_count > 1 {
		reached_vertex: [MAX_VERTICES]bool
		stack: [MAX_VERTICES]int
		stack_size, reached := 1, 0
		stack[0] = 0
		reached_vertex[0] = true
		for stack_size > 0 {
			stack_size -= 1
			vertex := stack[stack_size]
			reached += 1
			for i := 0; i < degree[vertex]; i += 1 {
				neighbor := int(neighbors[vertex*MAX_VERTICES+i])
				if !reached_vertex[neighbor] {
					reached_vertex[neighbor] = true
					stack[stack_size] = neighbor
					stack_size += 1
				}
			}
		}
		if reached != vertex_count do return -1
	}

	visited: [MAX_VERTICES]bool
	parent: [MAX_VERTICES]i32
	heap: [MAX_VERTICES]i64
	positions: [MAX_VERTICES]i32
	node_position: [MAX_VERTICES]i32
	for vertex := 0; vertex < vertex_count; vertex += 1 {
		parent[vertex] = -1
		heap[vertex] = SOURCE_HEAP_SENTINEL
		positions[vertex] = i32(vertex)
		node_position[vertex] = i32(vertex)
	}
	visited[0] = true
	for i := 0; i < degree[0]; i += 1 {
		neighbor := int(neighbors[i])
		parent[neighbor] = 0
		heap[neighbor] = i64(weights[i])
	}
	start := vertex_count/2
	for start > 0 {
		start -= 1
		top_to_bottom(&heap[0], &positions[0], &node_position[0], vertex_count, start)
	}

	words: [MAX_OUTPUT_WORDS]i32
	word_count, tree_edge_count := 1, 0
	for step := 1; step < vertex_count; step += 1 {
		vertex_id := positions[0]
		vertex := int(vertex_id)
		heap[0] = SOURCE_HEAP_SENTINEL
		top_to_bottom(&heap[0], &positions[0], &node_position[0], vertex_count, 0)
		if !visited[vertex] {
			words[word_count] = parent[vertex]
			words[word_count+1] = vertex_id
			word_count += 2
			tree_edge_count += 1
			visited[vertex] = true
			for i := 0; i < degree[vertex]; i += 1 {
				neighbor := int(neighbors[vertex*MAX_VERTICES+i])
				weight := weights[vertex*MAX_VERTICES+i]
				if !visited[neighbor] {
					heap_index := int(node_position[neighbor])
					if i64(weight) < heap[heap_index] {
						heap[heap_index] = i64(weight)
						decrease_key(i64(weight), heap_index, &heap[0], &positions[0], &node_position[0])
						parent[neighbor] = vertex_id
					}
				}
			}
		}
	}
	if tree_edge_count != vertex_count-1 do return -1
	words[0] = i32(tree_edge_count)
	bytes := word_count*4
	if bytes > MAX_OUTPUT_BYTES || output == nil || capacity < c.size_t(bytes) do return -2
	buffer: [MAX_OUTPUT_BYTES]u8
	for i := 0; i < word_count; i += 1 do put_i32_le(&buffer[0], i*4, words[i])
	for i := 0; i < bytes; i += 1 do output[i] = buffer[i]
	return i64(bytes)
}
