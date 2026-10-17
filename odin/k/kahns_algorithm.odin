package kahns_algorithm

import "core:c"

MAX_VERTICES :: 32
MAX_EDGES :: 128
MAX_INPUT_LENGTH :: 257

@(export, link_name="kahns_algorithm")
kahns_algorithm :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	edge_count_value := input[0]
	if edge_count_value < 0 || edge_count_value > MAX_EDGES do return -1
	edge_count := int(edge_count_value)
	if length != c.size_t(1 + 2 * edge_count) do return -1

	var labels: [MAX_VERTICES]i32
	var first_edge: [MAX_VERTICES]int
	var last_edge: [MAX_VERTICES]int
	var next_edge: [MAX_EDGES]int
	var to_by_edge: [MAX_EDGES]int
	var indegree: [MAX_VERTICES]int
	vertex_count := 0
	for vertex := 0; vertex < MAX_VERTICES; vertex += 1 {
		first_edge[vertex] = -1
		last_edge[vertex] = -1
	}
	for edge := 0; edge < edge_count; edge += 1 {
		from_value := input[1 + 2 * edge]
		to_value := input[2 + 2 * edge]
		if from_value < -2147483648 || from_value > 2147483647 ||
			to_value < -2147483648 || to_value > 2147483647 do return -1
		from_label := i32(from_value)
		to_label := i32(to_value)
		if from_label == to_label do return -1
		from_index := -1
		to_index := -1
		for i := 0; i < vertex_count; i += 1 {
			if labels[i] == from_label do from_index = i
			if labels[i] == to_label do to_index = i
		}
		if from_index < 0 {
			if vertex_count >= MAX_VERTICES do return -1
			from_index = vertex_count
			labels[vertex_count] = from_label
			vertex_count += 1
		}
		if to_index < 0 {
			if vertex_count >= MAX_VERTICES do return -1
			to_index = vertex_count
			labels[vertex_count] = to_label
			vertex_count += 1
		}
		to_by_edge[edge] = to_index
		next_edge[edge] = -1
		if first_edge[from_index] < 0 { first_edge[from_index] = edge }
		else { next_edge[last_edge[from_index]] = edge }
		last_edge[from_index] = edge
		indegree[to_index] += 1
	}

	var queue: [MAX_VERTICES]int
	var order: [MAX_VERTICES]int
	queue_head, queue_tail, order_count := 0, 0, 0
	for vertex := 0; vertex < vertex_count; vertex += 1 {
		if indegree[vertex] == 0 { queue[queue_tail] = vertex; queue_tail += 1 }
	}
	if vertex_count > 0 && queue_tail != 1 do return -1
	for queue_head < queue_tail {
		if queue_tail - queue_head != 1 do return -1
		current := queue[queue_head]
		queue_head += 1
		order[order_count] = current
		order_count += 1
		for outgoing := first_edge[current]; outgoing >= 0; outgoing = next_edge[outgoing] {
			adjacent := to_by_edge[outgoing]
			if indegree[adjacent] == 0 do return -1
			indegree[adjacent] -= 1
			if indegree[adjacent] == 0 { queue[queue_tail] = adjacent; queue_tail += 1 }
		}
	}
	if order_count != vertex_count do return -1

	output_bytes := 4 * order_count
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for i := 0; i < order_count; i += 1 {
		bits := u32(labels[order[i]])
		for byte := 0; byte < 4; byte += 1 {
			output[4 * i + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
	return i64(output_bytes)
}
