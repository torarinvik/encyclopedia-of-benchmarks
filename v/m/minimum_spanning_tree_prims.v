module minimum_spanning_tree_prims

const max_vertices = 16
const max_edges = 64
const max_parseable_input_length = 2 + 3 * max_edges + 1
const max_output_words = 1 + 2 * (max_vertices - 1)
const max_output_bytes = 4 * max_output_words
const source_heap_sentinel = i64(9223372036854775807)

fn top_to_bottom(mut heap [max_vertices]i64, mut positions [max_vertices]i32,
	mut node_position [max_vertices]i32, size int, start int) {
	mut root := start
	for root * 2 + 1 < size {
		left := root * 2 + 1
		right := left + 1
		mut child := left
		if right < size && heap[right] <= heap[left] { child = right }
		if heap[child] >= heap[root] { break }
		temp_heap := heap[root]
		heap[root] = heap[child]
		heap[child] = temp_heap
		temp_vertex := positions[root]
		positions[root] = positions[child]
		positions[child] = temp_vertex
		node_position[positions[root]] = i32(root)
		node_position[positions[child]] = i32(child)
		root = child
	}
}

fn decrease_key(value i64, index_start int, mut heap [max_vertices]i64,
	mut positions [max_vertices]i32, mut node_position [max_vertices]i32) {
	mut index := index_start
	vertex := positions[index]
	for index != 0 {
		parent := (index - 1) / 2
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

fn put_i32_le(mut output &u8, offset int, value i32) {
	mut bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'minimum_spanning_tree_prims']
pub fn minimum_spanning_tree_prims(input &i32, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > usize(max_parseable_input_length) { return -1 }
		raw_vertices := input[0]
		raw_edges := input[1]
		if raw_vertices < 1 || raw_vertices > max_vertices || raw_edges < 0 || raw_edges > max_edges {
			return -1
		}
		vertex_count := int(raw_vertices)
		edge_count := int(raw_edges)
		if length != usize(2 + 3 * edge_count) { return -1 }

		mut neighbors := [max_vertices][max_vertices]i32{}
		mut weights := [max_vertices][max_vertices]i32{}
		mut degree := [max_vertices]int{}
		mut seen := [max_vertices][max_vertices]bool{}
		mut position := 2
		for _ in 0 .. edge_count {
			u := input[position]
			v := input[position + 1]
			weight := input[position + 2]
			position += 3
			if u < 0 || v <= u || v >= raw_vertices || seen[u][v] { return -1 }
			seen[u][v] = true
			u_degree := degree[u]
			neighbors[u][u_degree] = v
			weights[u][u_degree] = weight
			degree[u]++
			v_degree := degree[v]
			neighbors[v][v_degree] = u
			weights[v][v_degree] = weight
			degree[v]++
		}

		if vertex_count > 1 {
			mut reached_vertex := [max_vertices]bool{}
			mut stack := [max_vertices]int{}
			mut stack_size := 1
			mut reached := 0
			stack[0] = 0
			reached_vertex[0] = true
			for stack_size > 0 {
				stack_size--
				vertex := stack[stack_size]
				reached++
				for i in 0 .. degree[vertex] {
					neighbor := neighbors[vertex][i]
					if !reached_vertex[neighbor] {
						reached_vertex[neighbor] = true
						stack[stack_size] = neighbor
						stack_size++
					}
				}
			}
			if reached != vertex_count { return -1 }
		}

		mut visited := [max_vertices]bool{}
		mut parent := [max_vertices]i32{}
		mut heap := [max_vertices]i64{}
		mut positions := [max_vertices]i32{}
		mut node_position := [max_vertices]i32{}
		for vertex in 0 .. vertex_count {
			parent[vertex] = -1
			heap[vertex] = source_heap_sentinel
			positions[vertex] = i32(vertex)
			node_position[vertex] = i32(vertex)
		}
		visited[0] = true
		for i in 0 .. degree[0] {
			neighbor := neighbors[0][i]
			parent[neighbor] = 0
			heap[neighbor] = i64(weights[0][i])
		}
		mut start := vertex_count / 2
		for start > 0 {
			start--
			top_to_bottom(mut heap, mut positions, mut node_position, vertex_count, start)
		}

		mut words := [max_output_words]i32{}
		mut word_count := 1
		mut tree_edge_count := 0
		for _ in 1 .. vertex_count {
			vertex_id := positions[0]
			vertex := int(vertex_id)
			heap[0] = source_heap_sentinel
			top_to_bottom(mut heap, mut positions, mut node_position, vertex_count, 0)
			if !visited[vertex] {
				words[word_count] = parent[vertex]
				words[word_count + 1] = vertex_id
				word_count += 2
				tree_edge_count++
				visited[vertex] = true
				for i in 0 .. degree[vertex] {
					neighbor := neighbors[vertex][i]
					weight := weights[vertex][i]
					if !visited[neighbor] {
						heap_index := int(node_position[neighbor])
						if i64(weight) < heap[heap_index] {
							heap[heap_index] = i64(weight)
							decrease_key(i64(weight), heap_index, mut heap, mut positions, mut node_position)
							parent[neighbor] = vertex_id
						}
					}
				}
			}
		}
		if tree_edge_count != vertex_count - 1 { return -1 }
		words[0] = i32(tree_edge_count)
		bytes := word_count * 4
		if bytes > max_output_bytes || output == nil || capacity < usize(bytes) { return -2 }
		mut buffer := [max_output_bytes]u8{}
		for i in 0 .. word_count { put_i32_le(mut buffer[0], i * 4, words[i]) }
		for i in 0 .. bytes { output[i] = buffer[i] }
		return i64(bytes)
	}
}
