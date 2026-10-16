module depth_first_search_iterative_order

const max_vertices = 10
const max_edges = 64
const max_degree = 128

fn put_i64_le(mut output &u8, word int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[word * 8 + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'depth_first_search_iterative_order']
pub fn depth_first_search_iterative_order(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 3 { return -1 }
	unsafe {
		n_value, edge_value := input[0], input[1]
		if n_value < 1 || n_value > max_vertices || edge_value < 0 || edge_value > max_edges { return -1 }
		n := int(n_value)
		edge_count := int(edge_value)
		if length != usize(3 + 2 * edge_count) { return -1 }
		mut adjacency := [11 * max_degree]int{}
		mut degree := [11]int{}
		mut position := 2
		for _ in 0 .. edge_count {
			left_value, right_value := input[position], input[position + 1]
			position += 2
			if left_value < 1 || left_value > n_value || right_value < 1 || right_value > n_value { return -1 }
			left, right := int(left_value), int(right_value)
			adjacency[left * max_degree + degree[left]] = right
			degree[left]++
			adjacency[right * max_degree + degree[right]] = left
			degree[right]++
		}
		start_value := input[position]
		if start_value < 1 || start_value > n_value { return -1 }
		start := int(start_value)
		mut visited := [11]bool{}
		mut stack := [max_vertices]int{}
		mut order := [max_vertices]int{}
		visited[start] = true
		mut stack_size := 1
		mut order_count := 0
		stack[0] = start
		for stack_size > 0 {
			stack_size--
			vertex := stack[stack_size]
			order[order_count] = vertex
			order_count++
			for edge in 0 .. degree[vertex] {
				neighbor := adjacency[vertex * max_degree + edge]
				if !visited[neighbor] {
					visited[neighbor] = true
					stack[stack_size] = neighbor
					stack_size++
				}
			}
		}
		words := order_count + 1
		if output == nil || capacity < usize(words * 8) { return -2 }
		put_i64_le(mut output, 0, i64(order_count))
		for index in 0 .. order_count { put_i64_le(mut output, index + 1, i64(order[index])) }
		return i64(words * 8)
	}
}
