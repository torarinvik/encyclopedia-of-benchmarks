module search_in_bst

const max_node_count = 5000
const max_value = 10000000

// Follow the unique BST branch until the target node or an empty child.
@[export: 'search_in_bst']
pub fn search_in_bst(input &i64, length usize) i64 {
	if length < 3 { return -1 }
	unsafe {
		count_value := input[0]
		root := input[1]
		target := input[2]
		if count_value < 0 || count_value > max_node_count ||
			length != usize(3 + 3 * count_value) || target < 1 || target > max_value { return -1 }
		count := usize(count_value)
		if count == 0 { return -1 }
		if root < 0 || u64(root) >= u64(count) { return -1 }
		mut node := root
		for node != -1 {
			if node < 0 || u64(node) >= u64(count) { return -1 }
			offset := 3 + 3 * int(node)
			value := input[offset]
			left := input[offset + 1]
			right := input[offset + 2]
			if value < 1 || value > max_value || left < -1 || right < -1 ||
				(left >= 0 && u64(left) >= u64(count)) ||
				(right >= 0 && u64(right) >= u64(count)) { return -1 }
			if value == target { return node }
			node = if target < value { left } else { right }
		}
		return -1
	}
}
