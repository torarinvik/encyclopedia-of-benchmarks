module breadth_first_search_zero_one_shortest_path

const max_vertices = 64
const max_edges = 256
const max_input_length = 4 + 3 * max_edges
const max_deque_capacity = max_vertices * max_vertices + 1

@[export: 'breadth_first_search_zero_one_shortest_path']
pub fn breadth_first_search_zero_one_shortest_path(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 4 || length > max_input_length { return -2 }
	unsafe {
		vertex_value, edge_value, start_value, finish_value := input[0], input[1], input[2], input[3]
		if vertex_value < 1 || vertex_value > max_vertices || edge_value < 0 || edge_value > max_edges { return -2 }
		vertices, edges := int(vertex_value), int(edge_value)
		if length != usize(4 + 3 * edges) || start_value < 0 || start_value >= vertex_value ||
			finish_value < 0 || finish_value >= vertex_value { return -2 }

		mut edge_to := [max_edges]int{}
		mut edge_weight := [max_edges]i64{}
		mut next_edge := [max_edges]int{init: -1}
		mut head_edge := [max_vertices]int{init: -1}
		mut tail_edge := [max_vertices]int{init: -1}
		for edge in 0 .. edges {
			from_value, to_value, weight_value := input[4 + 3 * edge], input[5 + 3 * edge], input[6 + 3 * edge]
			if from_value < 0 || from_value >= vertex_value || to_value < 0 || to_value >= vertex_value ||
				(weight_value != 0 && weight_value != 1) { return -2 }
			source := int(from_value)
			edge_to[edge] = int(to_value)
			edge_weight[edge] = weight_value
			if head_edge[source] < 0 { head_edge[source] = edge }
			else { next_edge[tail_edge[source]] = edge }
			tail_edge[source] = edge
		}

		start, finish := int(start_value), int(finish_value)
		mut distance := [max_vertices]i64{init: 1000000000}
		mut deque := [max_deque_capacity]int{}
		mut deque_head := 0
		mut deque_count := 1
		distance[start] = 0
		deque[0] = start
		for deque_count > 0 {
			node := deque[deque_head]
			deque_head = (deque_head + 1) % max_deque_capacity
			deque_count--
			edge := head_edge[node]
			for edge >= 0 {
				neighbor := edge_to[edge]
				candidate := distance[node] + edge_weight[edge]
				if candidate < distance[neighbor] {
					distance[neighbor] = candidate
					if edge_weight[edge] == 0 {
						deque_head = (deque_head + max_deque_capacity - 1) % max_deque_capacity
						deque[deque_head] = neighbor
					} else {
						deque[(deque_head + deque_count) % max_deque_capacity] = neighbor
					}
					deque_count++
				}
				edge = next_edge[edge]
			}
		}
		if distance[finish] == 1000000000 { return -1 }
		return distance[finish]
	}
}
