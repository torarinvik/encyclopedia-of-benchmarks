package vertical_order_traversal

import "core:c"

MAX_NODES :: 1023
COLUMN_COUNT :: 2 * MAX_NODES + 1

@(export)
vertical_order_traversal :: proc "c" (nodes: [^]i64, node_count: c.size_t,
		root_index: i64, output_values: [^]i64, output_capacity: c.size_t,
		column_offsets: [^]c.size_t, offsets_capacity: c.size_t,
		queue: [^]c.size_t, queue_capacity: c.size_t) -> i64 {
	if node_count > MAX_NODES do return -1
	if node_count == 0 {
		if root_index != -1 do return -1
		if column_offsets == nil || offsets_capacity < 1 do return -2
		column_offsets[0] = 0
		return 0
	}
	if nodes == nil || root_index < 0 || u64(root_index) >= u64(node_count) do return -1
	if output_values == nil || output_capacity < node_count || column_offsets == nil ||
		offsets_capacity < node_count + 1 || queue == nil || queue_capacity < node_count do return -2
	parents: [MAX_NODES]int
	for node := 0; node < int(node_count); node += 1 {
		value, left, right := nodes[3 * node], nodes[3 * node + 1], nodes[3 * node + 2]
		if value < i64(-2147483648) || value > i64(2147483647) || left < -1 || right < -1 ||
			(left >= 0 && u64(left) >= u64(node_count)) || (right >= 0 && u64(right) >= u64(node_count)) do return -1
		if left >= 0 { parents[int(left)] += 1; if parents[int(left)] > 1 do return -1 }
		if right >= 0 { parents[int(right)] += 1; if parents[int(right)] > 1 do return -1 }
	}
	root := int(root_index)
	if parents[root] != 0 do return -1
	for node := 0; node < int(node_count); node += 1 do if node != root && parents[node] != 1 do return -1
	columns: [MAX_NODES]i64
	next_column: [MAX_NODES]i64
	bucket_head: [COLUMN_COUNT]i64
	bucket_tail: [COLUMN_COUNT]i64
	visited: [MAX_NODES]bool
	for slot := 0; slot < COLUMN_COUNT; slot += 1 { bucket_head[slot] = -1; bucket_tail[slot] = -1 }
	top, head, reached := 1, 0, 0
	minimum, maximum := i64(0), i64(0)
	queue[0] = c.size_t(root); columns[root] = 0; visited[root] = true
	for head < top {
		node := int(queue[head]); head += 1
		coordinate := columns[node]
		slot := int(coordinate + MAX_NODES)
		next_column[node] = -1
		if bucket_head[slot] < 0 { bucket_head[slot] = i64(node) }
		else { next_column[int(bucket_tail[slot])] = i64(node) }
		bucket_tail[slot] = i64(node); reached += 1
		left, right := nodes[3 * node + 1], nodes[3 * node + 2]
		if left >= 0 {
			child := int(left)
			if visited[child] || c.size_t(top) >= queue_capacity do return -1
			visited[child] = true; columns[child] = coordinate - 1; queue[top] = c.size_t(child); top += 1
			minimum = min(minimum, columns[child])
		}
		if right >= 0 {
			child := int(right)
			if visited[child] || c.size_t(top) >= queue_capacity do return -1
			visited[child] = true; columns[child] = coordinate + 1; queue[top] = c.size_t(child); top += 1
			maximum = max(maximum, columns[child])
		}
	}
	if reached != int(node_count) do return -1
	written, column_count := 0, 0
	column_offsets[0] = 0
	for coordinate := minimum; coordinate <= maximum; coordinate += 1 {
		slot := int(coordinate + MAX_NODES)
		node := bucket_head[slot]
		for node >= 0 {
			output_values[written] = nodes[3 * int(node)]; written += 1
			node = next_column[int(node)]
		}
		column_count += 1; column_offsets[column_count] = c.size_t(written)
	}
	return i64(column_count)
}
