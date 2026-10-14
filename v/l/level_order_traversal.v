module level_order_traversal

// Breadth-first indexed binary-tree traversal, recording each level boundary.
@[export: 'level_order_traversal']
pub fn level_order_traversal(nodes &i64, node_count usize, root_index i64,
		output_values &i64, output_capacity usize, level_offsets &usize,
		level_offsets_capacity usize, queue &usize, queue_capacity usize) i64 {
	if node_count == 0 {
		if root_index != -1 { return -1 }
		if level_offsets_capacity < 1 { return -2 }
		unsafe { level_offsets[0] = 0 }
		return 0
	}
	if node_count > 4096 || root_index < 0 || u64(root_index) >= u64(node_count) { return -1 }
	if output_capacity < node_count || level_offsets_capacity < node_count + 1 || queue_capacity < node_count {
		return -2
	}
	mut head := usize(0)
	mut tail := usize(1)
	mut visited := usize(0)
	mut levels := usize(0)
	unsafe {
		queue[0] = usize(root_index)
		level_offsets[0] = 0
	}
	for head < tail {
		level_end := tail
		for head < level_end {
			unsafe {
				node := queue[head]
				head++
				output_values[visited] = nodes[3 * node]
				visited++
				left := nodes[3 * node + 1]
				right := nodes[3 * node + 2]
				if left < -1 || right < -1 { return -1 }
				if left >= 0 {
					if u64(left) >= u64(node_count) || tail >= queue_capacity { return -1 }
					queue[tail] = usize(left)
					tail++
				}
				if right >= 0 {
					if u64(right) >= u64(node_count) || tail >= queue_capacity { return -1 }
					queue[tail] = usize(right)
					tail++
				}
			}
		}
		levels++
		unsafe { level_offsets[levels] = visited }
	}
	if visited != node_count { return -1 }
	return i64(levels)
}
