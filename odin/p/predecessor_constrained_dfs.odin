package predecessor_constrained_dfs

MAX_NODES :: 16
MAX_INPUT_VALUES :: 2 + MAX_NODES * MAX_NODES
MAX_EVENTS :: MAX_NODES + MAX_NODES * (MAX_NODES - 1) / 2

visit_node :: proc "contextless" (node, count: int, adjacent, predecessors: [^]bool,
		visited: [^]bool, events: [^]i64, event_count, next_order: ^int) -> bool {
	if event_count^ >= MAX_EVENTS do return false
	visited[node] = true
	index := 3 * event_count^
	events[index], events[index + 1], events[index + 2] = 1, i64(node), i64(next_order^)
	event_count^ += 1
	next_order^ += 1
	for child := 0; child < count; child += 1 {
		if !adjacent[node * MAX_NODES + child] || visited[child] do continue
		all_visited := true
		for parent := 0; parent < count; parent += 1 {
			if predecessors[child * MAX_NODES + parent] && !visited[parent] {
				all_visited = false
				break
			}
		}
		if all_visited {
			if !visit_node(child, count, adjacent, predecessors, visited, events, event_count, next_order) do return false
		} else {
			if event_count^ >= MAX_EVENTS do return false
			index = 3 * event_count^
			events[index], events[index + 1], events[index + 2] = 0, i64(child), -1
			event_count^ += 1
		}
	}
	return true
}

write_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 4; byte += 1 do output[offset + byte] = u8((bits >> (8 * byte)) & 0xff)
}

@(export)
predecessor_constrained_dfs :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_VALUES do return -1
	raw_count, raw_start := input[0], input[1]
	if raw_count < 1 || raw_count > MAX_NODES || raw_start < 0 || raw_start >= raw_count do return -1
	count := int(raw_count)
	if int(length) != 2 + count * count do return -1
	adjacent: [MAX_NODES * MAX_NODES]bool
	predecessors: [MAX_NODES * MAX_NODES]bool
	indegree: [MAX_NODES]int
	for from := 0; from < count; from += 1 {
		for to := 0; to < count; to += 1 {
			bit := input[2 + from * count + to]
			if (bit != 0 && bit != 1) || (from == to && bit != 0) do return -1
			if bit == 1 {
				adjacent[from * MAX_NODES + to] = true
				predecessors[to * MAX_NODES + from] = true
				indegree[to] += 1
			}
		}
	}
	queue: [MAX_NODES]int
	head, tail := 0, 0
	for node := 0; node < count; node += 1 do if indegree[node] == 0 { queue[tail] = node; tail += 1 }
	for head < tail {
		node := queue[head]
		head += 1
		for child := 0; child < count; child += 1 {
			if adjacent[node * MAX_NODES + child] {
				indegree[child] -= 1
				if indegree[child] == 0 { queue[tail] = child; tail += 1 }
			}
		}
	}
	if tail != count do return -1
	visited: [MAX_NODES]bool
	events: [MAX_EVENTS * 3]i64
	event_count, next_order := 0, 0
	if !visit_node(int(raw_start), count, &adjacent[0], &predecessors[0], &visited[0], &events[0], &event_count, &next_order) do return -1
	byte_count := 12 * event_count
	if output == nil || int(output_capacity) < byte_count do return -2
	for event := 0; event < event_count; event += 1 {
		index := 3 * event
		write_i32_le(output, 12 * event, events[index])
		write_i32_le(output, 12 * event + 4, events[index + 1])
		write_i32_le(output, 12 * event + 8, events[index + 2])
	}
	return i64(byte_count)
}
