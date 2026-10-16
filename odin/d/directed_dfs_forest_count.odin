package directed_dfs_forest_count

import "core:c"

MAX_EDGE_COUNT :: 64
MAX_VERTEX_ID :: i64(63)
MAX_NODE_COUNT :: 128
MAX_INPUT_LENGTH :: 1 + 2 * MAX_EDGE_COUNT

find_last_node :: proc "contextless" (label: i64, labels: [^]i64, node_count: int) -> int {
	found := MAX_NODE_COUNT
	for node := 0; node < node_count; node += 1 {
		if labels[node] == label do found = node
	}
	return found
}

visit :: proc "contextless" (current, edge_count: int, edge_starts, edge_ends: [^]int,
		visited: [^]bool) {
	visited[current] = true
	for edge := 0; edge < edge_count; edge += 1 {
		destination := edge_ends[edge]
		if edge_starts[edge] == current && !visited[destination] {
			visit(destination, edge_count, edge_starts, edge_ends, visited)
		}
	}
}

@(export)
directed_dfs_forest_count :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH + 1) do return -1
	edge_count_value := input[0]
	if edge_count_value < 0 || edge_count_value > MAX_EDGE_COUNT do return -1
	edge_count := int(edge_count_value)
	if int(length) != 1 + 2 * edge_count do return -1

	labels: [MAX_NODE_COUNT]i64
	edge_starts: [MAX_EDGE_COUNT]int
	edge_ends: [MAX_EDGE_COUNT]int
	node_count := 0
	for edge := 0; edge < edge_count; edge += 1 {
		start_label, end_label := input[1 + 2 * edge], input[2 + 2 * edge]
		if start_label < 0 || start_label > MAX_VERTEX_ID || end_label < 0 || end_label > MAX_VERTEX_ID do return -1

		start := find_last_node(start_label, &labels[0], node_count)
		end := MAX_NODE_COUNT
		if start_label == end_label {
			if start == MAX_NODE_COUNT {
				start = node_count
				labels[node_count] = start_label
				node_count += 1
			}
			end = node_count
			labels[node_count] = end_label
			node_count += 1
		} else {
			end = find_last_node(end_label, &labels[0], node_count)
			if start == MAX_NODE_COUNT {
				start = node_count
				labels[node_count] = start_label
				node_count += 1
			}
			if end == MAX_NODE_COUNT {
				end = node_count
				labels[node_count] = end_label
				node_count += 1
			}
		}
		edge_starts[edge] = start
		edge_ends[edge] = end
	}

	marked: [MAX_NODE_COUNT]bool
	roots := i64(0)
	for root := 0; root < node_count; root += 1 {
		if marked[root] do continue
		visited: [MAX_NODE_COUNT]bool
		visit(root, edge_count, &edge_starts[0], &edge_ends[0], &visited[0])
		for node := 0; node < node_count; node += 1 {
			if visited[node] do marked[node] = true
		}
		roots += 1
	}
	return roots
}
