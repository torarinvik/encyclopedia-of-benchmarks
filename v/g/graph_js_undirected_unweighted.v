module graph_js_undirected_unweighted

const max_vertices = 26
const max_edges = 256
const max_degree = 512
const max_input_length = 541
const max_output_values = 645
const max_queue = 513

fn store_i64_le(mut output &u8, offset int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'graph_js_undirected_unweighted']
pub fn graph_js_undirected_unweighted(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 4 || length > max_input_length || unsafe { values == nil } { return -1 }
	unsafe {
		raw_vertex_count := values[0]
		if raw_vertex_count < 1 || raw_vertex_count > i64(max_vertices) { return -1 }
		vertex_count := int(raw_vertex_count)
		if int(length) < 1 + vertex_count + 2 { return -1 }
		mut vertices := [max_vertices]int{}
		mut declared := [max_vertices]bool{}
		for index in 0 .. vertex_count {
			value := values[1 + index]
			if value < 97 || value > 122 { return -1 }
			vertex := int(value - 97)
			if declared[vertex] { return -1 }
			declared[vertex] = true
			vertices[index] = vertex
		}
		edge_count_offset := 1 + vertex_count
		raw_edge_count := values[edge_count_offset]
		if raw_edge_count < 0 || raw_edge_count > i64(max_edges) { return -1 }
		edge_count := int(raw_edge_count)
		if int(length) != 1 + vertex_count + 1 + 2 * edge_count + 1 { return -1 }

		mut adjacency := [max_vertices * max_degree]u8{}
		mut degree := [max_vertices]int{}
		mut position := edge_count_offset + 1
		for _ in 0 .. edge_count {
			left_value := values[position]
			right_value := values[position + 1]
			position += 2
			if left_value < 97 || left_value > 122 || right_value < 97 || right_value > 122 { return -1 }
			left := int(left_value - 97)
			right := int(right_value - 97)
			if declared[left] && declared[right] {
				if degree[left] >= max_degree || degree[right] >= max_degree { return -1 }
				adjacency[left * max_degree + degree[left]] = u8(right)
				degree[left]++
				adjacency[right * max_degree + degree[right]] = u8(left)
				degree[right]++
			}
		}
		start_value := values[position]
		if start_value < 97 || start_value > 122 { return -1 }
		start := int(start_value - 97)
		if !declared[start] { return -1 }

		mut encoded_values := [max_output_values]i64{}
		mut result_length := 0
		encoded_values[result_length] = i64(vertex_count)
		result_length++
		for index in 0 .. vertex_count {
			vertex := vertices[index]
			encoded_values[result_length] = i64(97 + vertex)
			encoded_values[result_length + 1] = i64(degree[vertex])
			result_length += 2
			for edge in 0 .. degree[vertex] {
				encoded_values[result_length] = i64(97 + int(adjacency[vertex * max_degree + edge]))
				result_length++
			}
		}

		mut visited := [max_vertices]bool{}
		mut queue := [max_queue]int{}
		mut levels := [max_queue]int{}
		bfs_count_slot := result_length
		result_length++
		mut head := 0
		mut tail := 1
		queue[0] = start
		levels[0] = 0
		mut bfs_count := 0
		for head < tail {
			vertex := queue[head]
			level := levels[head]
			head++
			if visited[vertex] { continue }
			visited[vertex] = true
			encoded_values[result_length] = i64(97 + vertex)
			encoded_values[result_length + 1] = i64(level)
			result_length += 2
			bfs_count++
			for edge in 0 .. degree[vertex] {
				queue[tail] = int(adjacency[vertex * max_degree + edge])
				levels[tail] = level + 1
				tail++
			}
		}
		encoded_values[bfs_count_slot] = i64(bfs_count)

		for index in 0 .. max_vertices { visited[index] = false }
		dfs_count_slot := result_length
		result_length++
		mut stack_vertices := [max_vertices]int{}
		mut stack_next_edge := [max_vertices]int{}
		mut stack_depth := 1
		stack_vertices[0] = start
		visited[start] = true
		encoded_values[result_length] = i64(97 + start)
		result_length++
		mut dfs_count := 1
		for stack_depth > 0 {
			top := stack_depth - 1
			vertex := stack_vertices[top]
			if stack_next_edge[top] >= degree[vertex] {
				stack_depth--
				continue
			}
			edge := stack_next_edge[top]
			stack_next_edge[top]++
			neighbor := int(adjacency[vertex * max_degree + edge])
			if !visited[neighbor] {
				visited[neighbor] = true
				encoded_values[result_length] = i64(97 + neighbor)
				result_length++
				dfs_count++
				stack_vertices[stack_depth] = neighbor
				stack_next_edge[stack_depth] = 0
				stack_depth++
			}
		}
		encoded_values[dfs_count_slot] = i64(dfs_count)

		output_bytes := result_length * 8
		if output == nil || output_capacity < usize(output_bytes) { return -2 }
		for index in 0 .. result_length { store_i64_le(mut output, 8 * index, encoded_values[index]) }
		return i64(output_bytes)
	}
}
