module segment_tree_apply

const max_length = 64
const max_operations = 20
const max_tree_nodes = 128
const max_parseable_input_length = 147
const checksum_offset = i64(67108865)

fn apply_update(mut tree [max_tree_nodes]i64, mut operand [max_tree_nodes]i64, query_left int, query_right int, node int, left int, right int, factor i64) {
	if query_left <= left && right <= query_right {
		operand[node] *= factor
		tree[node] *= factor
		return
	}
	if query_right <= left || right <= query_left { return }
	middle := left + (right - left) / 2
	apply_update(mut tree, mut operand, query_left, query_right, node * 2, left, middle, factor)
	apply_update(mut tree, mut operand, query_left, query_right, node * 2 + 1, middle, right, factor)
	tree[node] = operand[node] * (tree[node * 2] + tree[node * 2 + 1])
}

fn query_sum(tree [max_tree_nodes]i64, operand [max_tree_nodes]i64, query_left int, query_right int, node int, left int, right int) i64 {
	if query_left <= left && right <= query_right { return tree[node] }
	if query_right <= left || right <= query_left { return 0 }
	middle := left + (right - left) / 2
	return operand[node] * (query_sum(tree, operand, query_left, query_right, node * 2, left, middle) +
		query_sum(tree, operand, query_left, query_right, node * 2 + 1, middle, right))
}

@[export: 'segment_tree_apply_benchmark']
pub fn segment_tree_apply_benchmark(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > usize(max_parseable_input_length) { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_length { return -1 }
		n := int(input[0])
		if length < usize(n + 2) { return -1 }
		if input[n + 1] < 0 || input[n + 1] > max_operations { return -1 }
		operation_count := int(input[n + 1])
		if length != usize(n + 2 + 4 * operation_count) || length > 146 { return -1 }
		mut base := 1
		for base < n { base <<= 1 }
		mut tree := [max_tree_nodes]i64{}
		mut operand := [max_tree_nodes]i64{}
		for i in 0 .. max_tree_nodes { operand[i] = 1 }
		for i in 0 .. n {
			value := input[i + 1]
			if value < -1 || value > 1 { return -1 }
			tree[base + i] = value
		}
		for node := base - 1; node > 0; node-- { tree[node] = tree[node * 2] + tree[node * 2 + 1] }
		mut checksum := i64(0)
		for operation in 0 .. operation_count {
			offset := n + 2 + 4 * operation
			opcode, left, right, argument := input[offset], input[offset + 1], input[offset + 2], input[offset + 3]
			if left < 0 || left > right || right >= i64(n) { return -1 }
			query_left, query_right := int(left), int(right + 1)
			if opcode == 0 {
				if argument < -2 || argument > 2 { return -1 }
				apply_update(mut tree, mut operand, query_left, query_right, 1, 0, base, argument)
			} else if opcode == 1 {
				if argument != 0 { return -1 }
				result := query_sum(tree, operand, query_left, query_right, 1, 0, base)
				checksum += i64(operation + 1) * (result + checksum_offset)
			} else { return -1 }
		}
		return checksum
	}
}
