package breadth_first_search_zero_one_shortest_path

import "core:c"

Max_Vertices :: 64
Max_Edges :: 256
Max_Input_Length :: 4 + 3 * Max_Edges
Max_Deque_Capacity :: Max_Vertices * Max_Vertices + 1

@(export)
breadth_first_search_zero_one_shortest_path :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > Max_Input_Length do return -2
	vertex_value, edge_value, start_value, finish_value := input[0], input[1], input[2], input[3]
	if vertex_value < 1 || vertex_value > Max_Vertices || edge_value < 0 || edge_value > Max_Edges do return -2
	vertices, edges := int(vertex_value), int(edge_value)
	if length != c.size_t(4 + 3 * edges) || start_value < 0 || start_value >= vertex_value ||
		finish_value < 0 || finish_value >= vertex_value do return -2

	var edge_to: [Max_Edges]int
	var edge_weight: [Max_Edges]i64
	var next_edge: [Max_Edges]int
	var head_edge: [Max_Vertices]int
	var tail_edge: [Max_Vertices]int
	for vertex := 0; vertex < vertices; vertex += 1 {
		head_edge[vertex] = -1
		tail_edge[vertex] = -1
	}
	for edge := 0; edge < edges; edge += 1 {
		from_value, to_value, weight_value := input[4 + 3 * edge], input[5 + 3 * edge], input[6 + 3 * edge]
		if from_value < 0 || from_value >= vertex_value || to_value < 0 || to_value >= vertex_value ||
			(weight_value != 0 && weight_value != 1) do return -2
		source := int(from_value)
		edge_to[edge] = int(to_value)
		edge_weight[edge] = weight_value
		next_edge[edge] = -1
		if head_edge[source] < 0 do head_edge[source] = edge
		else next_edge[tail_edge[source]] = edge
		tail_edge[source] = edge
	}

	start, finish := int(start_value), int(finish_value)
	var distance: [Max_Vertices]i64
	for vertex := 0; vertex < vertices; vertex += 1 do distance[vertex] = 1_000_000_000
	var deque: [Max_Deque_Capacity]int
	deque_head, deque_count := 0, 1
	distance[start] = 0
	deque[0] = start
	for deque_count > 0 {
		node := deque[deque_head]
		deque_head = (deque_head + 1) % Max_Deque_Capacity
		deque_count -= 1
		edge := head_edge[node]
		for edge >= 0 {
			neighbor := edge_to[edge]
			candidate := distance[node] + edge_weight[edge]
			if candidate < distance[neighbor] {
				distance[neighbor] = candidate
				if edge_weight[edge] == 0 {
					deque_head = (deque_head + Max_Deque_Capacity - 1) % Max_Deque_Capacity
					deque[deque_head] = neighbor
				} else {
					deque[(deque_head + deque_count) % Max_Deque_Capacity] = neighbor
				}
				deque_count += 1
			}
			edge = next_edge[edge]
		}
	}
	if distance[finish] == 1_000_000_000 do return -1
	return distance[finish]
}
