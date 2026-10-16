module boundary_traversal

const max_node_count = 100

fn validate(nodes &i64, node_count usize, node i64, mut seen []bool, mut reached &usize) bool {
	if node == -1 {
		return true
	}
	if node < 0 || u64(node) >= u64(node_count) {
		return false
	}
	index := usize(node)
	if seen[index] {
		return false
	}
	seen[index] = true
	reached[0]++
	unsafe {
		value, left, right := nodes[3 * index], nodes[3 * index + 1], nodes[3 * index + 2]
		if value < -2147483648 || value > 2147483647 || left < -1 || right < -1 ||
			(left >= 0 && u64(left) >= u64(node_count)) ||
			(right >= 0 && u64(right) >= u64(node_count)) {
			return false
		}
		return validate(nodes, node_count, left, mut seen, mut reached) &&
			validate(nodes, node_count, right, mut seen, mut reached)
	}
}

fn is_leaf(nodes &i64, index usize) bool {
	unsafe {
		return nodes[3 * index + 1] == -1 && nodes[3 * index + 2] == -1
	}
}

fn emit_leaves(nodes &i64, node i64, mut output &i64, mut used &usize) {
	if node == -1 {
		return
	}
	index := usize(node)
	if is_leaf(nodes, index) {
		unsafe {
			output[used[0]] = nodes[3 * index]
		}
		used[0]++
		return
	}
	unsafe {
		emit_leaves(nodes, nodes[3 * index + 1], mut output, mut used)
		emit_leaves(nodes, nodes[3 * index + 2], mut output, mut used)
	}
}

@[export: 'boundary_traversal']
pub fn boundary_traversal(nodes &i64, node_count usize, root_index i64,
	mut output &i64, output_capacity usize) i64 {
	if node_count > max_node_count || output_capacity < node_count {
		return -1
	}
	if node_count == 0 {
		return if root_index == -1 { i64(0) } else { i64(-1) }
	}
	if unsafe { nodes == nil } || unsafe { output == nil } || root_index < 0 ||
		u64(root_index) >= u64(node_count) {
		return -1
	}
	mut seen := []bool{len: int(node_count), init: false}
	mut reached := usize(0)
	if !validate(nodes, node_count, root_index, mut seen, mut reached) || reached != node_count {
		return -1
	}

	root := usize(root_index)
	mut used := usize(0)
	if !is_leaf(nodes, root) {
		unsafe {
			output[used] = nodes[3 * root]
		}
		used++
	}
	mut current := unsafe { nodes[3 * root + 1] }
	if current == -1 && unsafe { nodes[3 * root + 2] != -1 } {
		current = unsafe { nodes[3 * root + 2] }
	}
	for current != -1 {
		index := usize(current)
		if !is_leaf(nodes, index) {
			unsafe {
				output[used] = nodes[3 * index]
			}
			used++
		}
		unsafe {
			current = if nodes[3 * index + 1] != -1 {
				nodes[3 * index + 1]
			} else {
				nodes[3 * index + 2]
			}
		}
	}

	emit_leaves(nodes, root_index, mut output, mut used)
	if unsafe { nodes[3 * root + 2] != -1 && nodes[3 * root + 1] == -1 } {
		return i64(used)
	}
	mut right_boundary := []i64{len: int(node_count), init: 0}
	mut right_count := usize(0)
	current = unsafe { nodes[3 * root + 2] }
	for current != -1 {
		index := usize(current)
		if !is_leaf(nodes, index) {
			unsafe {
				right_boundary[right_count] = nodes[3 * index]
			}
			right_count++
		}
		unsafe {
			current = if nodes[3 * index + 2] != -1 {
				nodes[3 * index + 2]
			} else {
				nodes[3 * index + 1]
			}
		}
	}
	for right_count > 0 {
		right_count--
		unsafe {
			output[used] = right_boundary[right_count]
		}
		used++
	}
	return i64(used)
}
