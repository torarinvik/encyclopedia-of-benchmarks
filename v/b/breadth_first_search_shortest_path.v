module breadth_first_search_shortest_path

const max_vertices = 32
const max_edges = 256
const max_input_length = 4 + 2 * max_edges
const max_output_values = 1 + max_vertices

fn put_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'breadth_first_search_shortest_path']
pub fn breadth_first_search_shortest_path(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 4 || length > max_input_length { return -1 }
	unsafe {
		vertex_value, edge_value, start_value, goal_value := input[0], input[1], input[2], input[3]
		if vertex_value < 1 || vertex_value > max_vertices || edge_value < 0 || edge_value > max_edges { return -1 }
		vertices, edges := int(vertex_value), int(edge_value)
		if length != usize(4 + 2 * edges) || start_value < 0 || start_value >= i64(vertices) || goal_value < 0 || goal_value >= i64(vertices) { return -1 }
		mut adjacency := [max_vertices * max_edges]int{}
		mut degree := [max_vertices]int{}
		for edge in 0 .. edges {
			from_value, to_value := input[4 + 2 * edge], input[5 + 2 * edge]
			if from_value < 0 || from_value >= i64(vertices) || to_value < 0 || to_value >= i64(vertices) { return -1 }
			source := int(from_value)
			adjacency[source * max_edges + degree[source]] = int(to_value)
			degree[source]++
		}
		start, goal := int(start_value), int(goal_value)
		mut parent := [max_vertices]i64{init: -1}
		mut visited := [max_vertices]bool{}
		mut queue := [max_vertices]int{}
		mut head := 0
		mut tail := 0
		visited[start] = true
		queue[tail] = start
		tail++
		for head < tail && !visited[goal] {
			node := queue[head]
			head++
			for index in 0 .. degree[node] {
				neighbor := adjacency[node * max_edges + index]
				if visited[neighbor] { continue }
				visited[neighbor] = true
				parent[neighbor] = i64(node)
				queue[tail] = neighbor
				tail++
				if neighbor == goal { break }
			}
		}
		mut encoded := [max_output_values]i64{}
		mut path_count := 0
		if visited[goal] {
			mut reverse_path := [max_vertices]int{}
			mut current := goal
			for current >= 0 {
				reverse_path[path_count] = current
				path_count++
				if current == start { break }
				current = int(parent[current])
			}
			for index in 0 .. path_count { encoded[1 + index] = i64(reverse_path[path_count - 1 - index]) }
		}
		encoded[0] = i64(path_count)
		required := (path_count + 1) * 8
		if capacity < required || (required != 0 && output == nil) { return -2 }
		for index in 0 .. (path_count + 1) { put_i64(mut output, index * 8, encoded[index]) }
		return i64(required)
	}
}
