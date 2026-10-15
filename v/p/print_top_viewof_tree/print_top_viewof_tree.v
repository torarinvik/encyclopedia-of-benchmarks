module print_top_viewof_tree

const max_nodes = 1023

@[export: 'print_top_viewof_tree']
pub fn print_top_viewof_tree(nodes &i64, node_count usize, root_index i64,
	output_values &i64, output_capacity usize, column_offsets &usize,
	offsets_capacity usize, queue &usize, queue_capacity usize) i64 {
	if node_count > max_nodes { return -1 }
	if node_count == 0 {
		if root_index != -1 { return -1 }
		if offsets_capacity < 1 { return -2 }
		unsafe { column_offsets[0] = 0 }
		return 0
	}
	if root_index < 0 || u64(root_index) >= u64(node_count) { return -1 }
	if output_capacity < node_count || offsets_capacity < node_count + 1 || queue_capacity < node_count { return -2 }
	unsafe {
		mut parents := [max_nodes]int{}
		for node in 0 .. int(node_count) {
			value := nodes[3 * node]
			left := nodes[3 * node + 1]
			right := nodes[3 * node + 2]
			if value < -2147483648 || value > 2147483647 || left < -1 || right < -1 ||
				(left >= 0 && u64(left) >= u64(node_count)) || (right >= 0 && u64(right) >= u64(node_count)) { return -1 }
			if left >= 0 { parents[int(left)]++; if parents[int(left)] > 1 { return -1 } }
			if right >= 0 { parents[int(right)]++; if parents[int(right)] > 1 { return -1 } }
		}
		root := int(root_index)
		if parents[root] != 0 { return -1 }
		for node in 0 .. int(node_count) { if node != root && parents[node] != 1 { return -1 } }
		mut columns := [max_nodes]i64{}
		mut seen_column := [2 * max_nodes + 1]bool{}
		mut visited := [max_nodes]bool{}
		mut head := 0
		mut tail := 1
		mut reached := 0
		mut written := 0
		column_offsets[0] = 0
		queue[0] = usize(root); columns[root] = 0; visited[root] = true
		for head < tail {
			node := int(queue[head]); head++
			coordinate := columns[node]
			slot := int(coordinate + max_nodes)
			if !seen_column[slot] { seen_column[slot] = true; output_values[written] = nodes[3 * node]; written++; column_offsets[written] = usize(written) }
			reached++
			left := nodes[3 * node + 1]
			right := nodes[3 * node + 2]
			if left >= 0 {
				child := int(left)
				if visited[child] || usize(tail) >= queue_capacity { return -1 }
				visited[child] = true; columns[child] = coordinate - 1; queue[tail] = usize(child); tail++
			}
			if right >= 0 {
				child := int(right)
				if visited[child] || usize(tail) >= queue_capacity { return -1 }
				visited[child] = true; columns[child] = coordinate + 1; queue[tail] = usize(child); tail++
			}
		}
		if reached != int(node_count) { return -1 }
		return i64(written)
	}
}
