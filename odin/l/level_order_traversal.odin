package level_order_traversal

import "core:c"

// Breadth-first indexed binary-tree traversal, recording each level boundary.
@(export)
level_order_traversal :: proc "c" (nodes: [^]i64, node_count: c.size_t, root_index: i64,
		output_values: [^]i64, output_capacity: c.size_t,
		level_offsets: [^]c.size_t, level_offsets_capacity: c.size_t,
		queue: [^]c.size_t, queue_capacity: c.size_t) -> i64 {
	if node_count == 0 {
		if root_index != -1 do return -1
		if level_offsets == nil || level_offsets_capacity < 1 do return -2
		level_offsets[0] = 0
		return 0
	}
	if node_count > 4096 || nodes == nil || root_index < 0 || u64(root_index) >= u64(node_count) do return -1
	if output_values == nil || output_capacity < node_count || level_offsets == nil ||
		level_offsets_capacity < node_count + 1 || queue == nil || queue_capacity < node_count {
		return -2
	}

	head, tail, visited, levels := c.size_t(0), c.size_t(1), c.size_t(0), c.size_t(0)
	queue[0] = c.size_t(root_index)
	level_offsets[0] = 0
	for head < tail {
		level_end := tail
		for head < level_end {
			node := queue[head]
		head += 1
		output_values[visited] = nodes[3 * node]
		visited += 1
		left, right := nodes[3 * node + 1], nodes[3 * node + 2]
		if left < -1 || right < -1 do return -1
		if left >= 0 {
			if u64(left) >= u64(node_count) || tail >= queue_capacity do return -1
			queue[tail] = c.size_t(left)
			tail += 1
		}
		if right >= 0 {
			if u64(right) >= u64(node_count) || tail >= queue_capacity do return -1
			queue[tail] = c.size_t(right)
			tail += 1
		}
		}
		levels += 1
		level_offsets[levels] = visited
	}
	if visited != node_count do return -1
	return i64(levels)
}
