package dag_shortest_path

import "core:c"

MAX_VERTICES :: 12
MAX_EDGES :: 66
MAX_LENGTH :: 203
DISTANCE_OFFSET :: i64(100000)
INFINITY_DISTANCE :: i64(1) << 60

@(export)
dag_shortest_path :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > c.size_t(MAX_LENGTH) do return -1
	if input[0] < 1 || input[0] > MAX_VERTICES || input[1] < 0 || input[1] > MAX_EDGES do return -1
	vertex_count := int(input[0])
	edge_count := int(input[1])
	if length != c.size_t(4 + 3 * edge_count) do return -1
	if input[2] < 0 || input[2] >= i64(vertex_count) || input[3] < 0 || input[3] >= i64(vertex_count) do return -1
	from: [MAX_EDGES]i64
	to: [MAX_EDGES]i64
	weight: [MAX_EDGES]i64
	indegree: [MAX_VERTICES]i64
	queue: [MAX_VERTICES]int
	order: [MAX_VERTICES]int
	for edge := 0; edge < edge_count; edge += 1 {
		start := input[4+3*edge]
		finish := input[5+3*edge]
		cost := input[6+3*edge]
		if start < 0 || start >= i64(vertex_count) || finish < 0 || finish >= i64(vertex_count) do return -1
		if start == finish || cost < -1000 || cost > 1000 do return -1
		for previous := 0; previous < edge; previous += 1 {
			if from[previous] == start && to[previous] == finish do return -1
		}
		from[edge] = start
		to[edge] = finish
		weight[edge] = cost
		indegree[int(finish)] += 1
	}
	head, tail, order_count := 0, 0, 0
	for vertex := 0; vertex < vertex_count; vertex += 1 {
		if indegree[vertex] == 0 { queue[tail] = vertex; tail += 1 }
	}
	for head < tail {
		vertex := queue[head]
		head += 1
		order[order_count] = vertex
		order_count += 1
		for edge := 0; edge < edge_count; edge += 1 {
			if from[edge] == i64(vertex) {
				finish := int(to[edge])
				indegree[finish] -= 1
				if indegree[finish] == 0 { queue[tail] = finish; tail += 1 }
			}
		}
	}
	if order_count != vertex_count do return -1
	distance: [MAX_VERTICES]i64
	for vertex := 0; vertex < vertex_count; vertex += 1 { distance[vertex] = INFINITY_DISTANCE }
	distance[int(input[2])] = 0
	for position := 0; position < vertex_count; position += 1 {
		vertex := order[position]
		if distance[vertex] == INFINITY_DISTANCE do continue
		for edge := 0; edge < edge_count; edge += 1 {
			if from[edge] == i64(vertex) {
				finish := int(to[edge])
				candidate := distance[vertex] + weight[edge]
				if candidate < distance[finish] do distance[finish] = candidate
			}
		}
	}
	answer := distance[int(input[3])]
	if answer == INFINITY_DISTANCE do return 0
	return DISTANCE_OFFSET + answer
}
