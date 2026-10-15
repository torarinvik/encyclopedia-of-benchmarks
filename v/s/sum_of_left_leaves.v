module sum_of_left_leaves

const max_node_count = 1023

struct SumResult {
	value i64
	valid bool
}

fn sum_left_leaves_visit(nodes &i64, node_count usize, node i64, is_left bool) SumResult {
	if node == -1 { return SumResult{ value: 0, valid: true } }
	if node < 0 || u64(node) >= u64(node_count) { return SumResult{ value: 0, valid: false } }
	index := usize(node)
	unsafe {
		value := nodes[3 * index]
		left := nodes[3 * index + 1]
		right := nodes[3 * index + 2]
		if value < -1000 || value > 1000 || left < -1 ||
			(left >= 0 && u64(left) >= u64(node_count)) || right < -1 ||
			(right >= 0 && u64(right) >= u64(node_count)) {
			return SumResult{ value: 0, valid: false }
		}
		if left == -1 && right == -1 {
			return SumResult{ value: if is_left { value } else { i64(0) }, valid: true }
		}
		left_sum := sum_left_leaves_visit(nodes, node_count, left, true)
		if !left_sum.valid { return SumResult{ value: 0, valid: false } }
		right_sum := sum_left_leaves_visit(nodes, node_count, right, false)
		if !right_sum.valid { return SumResult{ value: 0, valid: false } }
		return SumResult{ value: left_sum.value + right_sum.value, valid: true }
	}
}

@[export: 'sum_of_left_leaves']
pub fn sum_of_left_leaves(nodes &i64, node_count usize, root_index i64) i64 {
	if node_count > max_node_count { return -1 }
	if node_count == 0 { return if root_index == -1 { i64(0) } else { i64(-1) } }
	if root_index < 0 || u64(root_index) >= u64(node_count) { return -1 }
	result := sum_left_leaves_visit(nodes, node_count, root_index, false)
	if !result.valid { return -1 }
	return result.value
}
