module range_sum_bst

const max_node_count = 1023
const max_value = 100000

// Preserve the source's full tree traversal while validating the BST input.
@[export: 'range_sum_bst']
pub fn range_sum_bst(nodes &i64, node_count usize, root_index i64, low i64, high i64) i64 {
	if node_count > max_node_count || low < 1 || high > max_value || low > high { return -1 }
	if node_count == 0 { return if root_index == -1 { i64(0) } else { i64(-1) } }
	if root_index < 0 || u64(root_index) >= u64(node_count) { return -1 }

	mut parents := [max_node_count]i64{}
	mut seen := [max_node_count]bool{}
	mut stack_node := [max_node_count]i64{}
	mut stack_low := [max_node_count]i64{}
	mut stack_high := [max_node_count]i64{}
	unsafe {
		for index in 0 .. max_node_count {
			parents[index] = 0
			seen[index] = false
		}
		for index in 0 .. node_count {
			value := nodes[3 * index]
			left := nodes[3 * index + 1]
			right := nodes[3 * index + 2]
			if value < 1 || value > max_value || left < -1 || right < -1 ||
				(left >= 0 && u64(left) >= u64(node_count)) ||
				(right >= 0 && u64(right) >= u64(node_count)) { return -1 }
			if left >= 0 {
				parents[int(left)]++
				if parents[int(left)] > 1 { return -1 }
			}
			if right >= 0 {
				parents[int(right)]++
				if parents[int(right)] > 1 { return -1 }
			}
		}
		root := usize(root_index)
		if parents[root] != 0 { return -1 }
		for index in 0 .. node_count {
			if index != root && parents[index] != 1 { return -1 }
		}

		mut top := 1
		mut visited := usize(0)
		stack_node[0] = root_index
		stack_low[0] = 0
		stack_high[0] = max_value + 1
		mut total := i64(0)
		for top > 0 {
			top--
			index := int(stack_node[top])
			lower := stack_low[top]
			upper := stack_high[top]
			if seen[index] { return -1 }
			seen[index] = true
			visited++
			value := nodes[3 * index]
			left := nodes[3 * index + 1]
			right := nodes[3 * index + 2]
			if value <= lower || value >= upper { return -1 }
			if low <= value && value <= high { total += value }
			if right >= 0 {
				stack_node[top] = right
				stack_low[top] = value
				stack_high[top] = upper
				top++
			}
			if left >= 0 {
				stack_node[top] = left
				stack_low[top] = lower
				stack_high[top] = value
				top++
			}
		}
		if visited != node_count { return -1 }
		return total
	}
}
