module kahns_algorithm

const max_vertices = 32
const max_edges = 128
const max_input_length = 257

@[export: 'kahns_algorithm']
pub fn kahns_algorithm(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_input_length { return -1 }
		edge_count_value := input[0]
		if edge_count_value < 0 || edge_count_value > max_edges { return -1 }
		edge_count := int(edge_count_value)
		if length != usize(1 + 2 * edge_count) { return -1 }

		mut labels := [max_vertices]i32{}
		mut first_edge := [max_vertices]int{}
		mut last_edge := [max_vertices]int{}
		mut next_edge := [max_edges]int{}
		mut to_by_edge := [max_edges]int{}
		mut indegree := [max_vertices]int{}
		mut vertex_count := 0
		for vertex in 0 .. max_vertices {
			first_edge[vertex] = -1
			last_edge[vertex] = -1
		}
		for edge in 0 .. edge_count {
			from_value := input[1 + 2 * edge]
			to_value := input[2 + 2 * edge]
			if from_value < -2147483648 || from_value > 2147483647 ||
				to_value < -2147483648 || to_value > 2147483647 { return -1 }
			from_label := i32(from_value)
			to_label := i32(to_value)
			if from_label == to_label { return -1 }
			mut from_index := -1
			mut to_index := -1
			for i in 0 .. vertex_count {
				if labels[i] == from_label { from_index = i }
				if labels[i] == to_label { to_index = i }
			}
			if from_index < 0 {
				if vertex_count >= max_vertices { return -1 }
				from_index = vertex_count
				labels[vertex_count] = from_label
				vertex_count++
			}
			if to_index < 0 {
				if vertex_count >= max_vertices { return -1 }
				to_index = vertex_count
				labels[vertex_count] = to_label
				vertex_count++
			}
			to_by_edge[edge] = to_index
			next_edge[edge] = -1
			if first_edge[from_index] < 0 { first_edge[from_index] = edge }
			else { next_edge[last_edge[from_index]] = edge }
			last_edge[from_index] = edge
			indegree[to_index]++
		}

		mut queue := [max_vertices]int{}
		mut order := [max_vertices]int{}
		mut queue_head := 0
		mut queue_tail := 0
		mut order_count := 0
		for vertex in 0 .. vertex_count {
			if indegree[vertex] == 0 { queue[queue_tail] = vertex; queue_tail++ }
		}
		if vertex_count > 0 && queue_tail != 1 { return -1 }
		for queue_head < queue_tail {
			if queue_tail - queue_head != 1 { return -1 }
			current := queue[queue_head]
			queue_head++
			order[order_count] = current
			order_count++
			mut outgoing := first_edge[current]
			for outgoing >= 0 {
				adjacent := to_by_edge[outgoing]
				if indegree[adjacent] == 0 { return -1 }
				indegree[adjacent]--
				if indegree[adjacent] == 0 { queue[queue_tail] = adjacent; queue_tail++ }
				outgoing = next_edge[outgoing]
			}
		}
		if order_count != vertex_count { return -1 }

		output_bytes := 4 * order_count
		if output == nil || capacity < usize(output_bytes) { return -2 }
		for i in 0 .. order_count {
			bits := u32(labels[order[i]])
			for byte in 0 .. 4 {
				output[4 * i + byte] = u8((bits >> (8 * byte)) & 255)
			}
		}
		return i64(output_bytes)
	}
}
