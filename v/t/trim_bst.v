module trim_bst

const max_node_count = 100

fn valid_bst(nodes &i64, node_count int, root_index int) bool {
	mut parents := [100]int{}
	unsafe {
		for index in 0 .. node_count {
			value := nodes[3 * index]
			left := nodes[3 * index + 1]
			right := nodes[3 * index + 2]
			if value < 1 || value > 10000 || left < -1 || right < -1 ||
				(left >= 0 && left >= i64(node_count)) || (right >= 0 && right >= i64(node_count)) { return false }
			if left >= 0 {
				parents[int(left)]++
				if parents[int(left)] > 1 { return false }
			}
			if right >= 0 {
				parents[int(right)]++
				if parents[int(right)] > 1 { return false }
			}
		}
	}
	if parents[root_index] != 0 { return false }
	for index in 0 .. node_count {
		if index != root_index && parents[index] != 1 { return false }
	}
	mut stack_node := [100]int{}
	mut stack_low := [100]i64{}
	mut stack_high := [100]i64{}
	mut seen := [100]bool{init: false}
	stack_node[0] = root_index
	stack_high[0] = 10001
	mut top := 1
	mut visited := 0
	for top > 0 {
		top--
		index := stack_node[top]
		lower := stack_low[top]
		upper := stack_high[top]
		if seen[index] { return false }
		seen[index] = true
		visited++
		unsafe {
			value := nodes[3 * index]
			if value <= lower || value >= upper { return false }
			left := nodes[3 * index + 1]
			right := nodes[3 * index + 2]
			if right >= 0 {
				stack_node[top] = int(right)
				stack_low[top] = value
				stack_high[top] = upper
				top++
			}
			if left >= 0 {
				stack_node[top] = int(left)
				stack_low[top] = lower
				stack_high[top] = value
				top++
			}
		}
	}
	return visited == node_count
}

fn trim_node(nodes &i64, node i64, low i64, high i64,
	mut output &i64, mut output_count &int) i64 {
	if node == -1 { return -1 }
	index := int(node)
	unsafe {
		value := nodes[3 * index]
		left := nodes[3 * index + 1]
		right := nodes[3 * index + 2]
		if value < low { return trim_node(nodes, right, low, high, mut output, mut output_count) }
		if value > high { return trim_node(nodes, left, low, high, mut output, mut output_count) }
		trimmed_index := output_count[0]
		output_count[0]++
		offset := 1 + 3 * trimmed_index
		output[offset] = value
		output[offset + 1] = -1
		output[offset + 2] = -1
		output[offset + 1] = trim_node(nodes, left, low, high, mut output, mut output_count)
		output[offset + 2] = trim_node(nodes, right, low, high, mut output, mut output_count)
		return i64(trimmed_index)
	}
}

@[export: 'trim_bst']
pub fn trim_bst(nodes &i64, node_count usize, root_index i64, low i64, high i64,
	mut output &i64, output_capacity usize) i64 {
	if node_count > max_node_count || low < 1 || high > 10000 || low > high { return -1 }
	if node_count == 0 {
		if root_index != -1 { return -1 }
		if output_capacity < 1 { return -2 }
		unsafe { output[0] = -1 }
		return 1
	}
	if root_index < 0 || u64(root_index) >= u64(node_count) { return -1 }
	if !valid_bst(nodes, int(node_count), int(root_index)) { return -1 }
	if output_capacity < 1 + 3 * node_count { return -2 }
	mut output_count := 0
	unsafe { output[0] = trim_node(nodes, root_index, low, high, mut output, mut output_count) }
	return i64(1 + 3 * output_count)
}
