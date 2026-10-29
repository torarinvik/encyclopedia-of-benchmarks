package k_shortest_walk

import "core:c"

MAX_VERTICES :: 6
MAX_EDGES :: 12
MAX_K :: 8
MAX_INPUT_LENGTH :: 41
MAX_FRONTIER :: 97

write_i64 :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8((bits >> (8*byte)) & 0xff)
	}
}

@(export)
k_shortest_walk :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > MAX_INPUT_LENGTH do return -1
	n_value, m_value, source_value, target_value, k_value := input[0], input[1], input[2], input[3], input[4]
	if n_value < 1 || n_value > MAX_VERTICES || m_value < 0 || m_value > MAX_EDGES ||
		k_value < 1 || k_value > MAX_K || source_value < 0 || source_value >= n_value ||
		target_value < 0 || target_value >= n_value do return -1
	n, m := int(n_value), int(m_value)
	source, target, k := int(source_value), int(target_value), int(k_value)
	if length != c.size_t(5 + 3*m) do return -1

	head: [MAX_VERTICES]i64
	for vertex := 0; vertex < n; vertex += 1 { head[vertex] = -1 }
	edge_to: [MAX_EDGES]i64 = 0
	edge_weight: [MAX_EDGES]i64 = 0
	edge_next: [MAX_EDGES]i64 = 0
	for edge := 0; edge < m; edge += 1 {
		u, v, weight := input[5+3*edge], input[6+3*edge], input[7+3*edge]
		if u < 0 || u >= n_value || v < 0 || v >= n_value || weight < 0 || weight > 1000 do return -1
		edge_to[edge] = v
		edge_weight[edge] = weight
		edge_next[edge] = head[int(u)]
		head[int(u)] = i64(edge)
	}
	if output == nil || output_capacity < c.size_t(8*k) do return -2

	queue_distance: [MAX_FRONTIER]i64 = 0
	queue_vertex: [MAX_FRONTIER]i64 = 0
	queue_order: [MAX_FRONTIER]i64 = 0
	expanded: [MAX_VERTICES]i64 = 0
	answers: [MAX_K]i64 = 0
	queue_count, answer_count := 1, 0
	next_order := i64(1)
	queue_distance[0], queue_vertex[0], queue_order[0] = 0, i64(source), 0

	for queue_count > 0 && answer_count < k {
		distance, vertex := queue_distance[0], int(queue_vertex[0])
		for slot := 1; slot < queue_count; slot += 1 {
			queue_distance[slot-1] = queue_distance[slot]
			queue_vertex[slot-1] = queue_vertex[slot]
			queue_order[slot-1] = queue_order[slot]
		}
		queue_count -= 1
		if expanded[vertex] >= i64(k) do continue
		expanded[vertex] += 1
		if vertex == target {
			answers[answer_count] = distance
			answer_count += 1
			if answer_count == k do break
		}
		for edge := head[vertex]; edge >= 0; edge = edge_next[int(edge)] {
			edge_index := int(edge)
			candidate_distance := distance + edge_weight[edge_index]
			candidate_vertex := edge_to[edge_index]
			candidate_order := next_order
			next_order += 1
			position := queue_count
			for position > 0 && (queue_distance[position-1] > candidate_distance ||
				(queue_distance[position-1] == candidate_distance && queue_order[position-1] > candidate_order)) {
				queue_distance[position] = queue_distance[position-1]
				queue_vertex[position] = queue_vertex[position-1]
				queue_order[position] = queue_order[position-1]
				position -= 1
			}
			queue_distance[position] = candidate_distance
			queue_vertex[position] = candidate_vertex
			queue_order[position] = candidate_order
			queue_count += 1
		}
	}
	for answer_count < k {
		answers[answer_count] = -1
		answer_count += 1
	}
	for index := 0; index < k; index += 1 { write_i64(output, 8*index, answers[index]) }
	return i64(8*k)
}
