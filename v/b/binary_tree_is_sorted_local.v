module binary_tree_is_sorted_local

const missing_node = i64(-2147483649)
const max_slots = 255

@[export: 'binary_tree_is_sorted_local']
pub fn binary_tree_is_sorted_local(nodes &i64, length usize) i64 {
	if length == 0 || length > max_slots || unsafe { nodes == nil } { return -1 }
	unsafe {
		if nodes[0] == missing_node { return -1 }
		for index in 0 .. int(length) {
			value := nodes[index]
			if value == missing_node { continue }
			if value < -2147483648 || value > 2147483647 { return -1 }
			if index > 0 {
				parent := (index - 1) / 2
				if nodes[parent] == missing_node { return -1 }
				if (index % 2 == 1 && value > nodes[parent]) ||
					(index % 2 == 0 && value < nodes[parent]) { return 0 }
			}
		}
	}
	return 1
}
