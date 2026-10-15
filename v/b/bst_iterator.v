module bst_iterator

const max_node_count = 1023

@[export: 'bst_iterator']
pub fn bst_iterator(nodes &i64, node_count usize, root_index i64) i64 {
	if node_count > max_node_count { return -1 }
	if node_count == 0 { return if root_index == -1 { i64(0) } else { i64(-1) } }
	if root_index < 0 || u64(root_index) >= u64(node_count) { return -1 }
	mut iterator_values := []i64{len: max_node_count, init: 0}
	mut stack := []usize{len: max_node_count, init: 0}
	mut top := usize(0)
	mut value_count := usize(0)
	mut current := root_index
	for current != -1 || top != 0 {
		for current != -1 {
			if current < 0 || u64(current) >= u64(node_count) || top >= node_count { return -1 }
			index := usize(current)
			left := unsafe { nodes[3 * index + 1] }
			right := unsafe { nodes[3 * index + 2] }
			if left < -1 || (left >= 0 && u64(left) >= u64(node_count)) ||
				right < -1 || (right >= 0 && u64(right) >= u64(node_count)) { return -1 }
			stack[top] = index
			top++
			current = left
		}
		top--
		index := stack[top]
		if value_count >= node_count { return -1 }
		value := unsafe { nodes[3 * index] }
		if value < -100000 || value > 100000 ||
			(value_count != 0 && iterator_values[value_count - 1] >= value) { return -1 }
		iterator_values[value_count] = value
		value_count++
		current = unsafe { nodes[3 * index + 2] }
	}
	if value_count != node_count { return -1 }
	mut checksum := i64(0)
	for next_index in 0 .. value_count {
		checksum += (i64(next_index) + 1) * (iterator_values[next_index] + 100001)
	}
	return checksum
}
