package segment_tree_apply

import "core:c"

MAX_LENGTH :: 64
MAX_OPERATIONS :: 20
MAX_TREE_NODES :: 128
MAX_VALID_INPUT_LENGTH :: c.size_t(146)
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(147)
CHECKSUM_OFFSET :: i64(67108865)

apply_update :: proc "contextless" (tree, operand: [^]i64, query_left, query_right, node, left, right: int, factor: i64) {
	if query_left <= left && right <= query_right {
		operand[node] *= factor
		tree[node] *= factor
		return
	}
	if query_right <= left || right <= query_left do return
	middle := left + (right-left)/2
	apply_update(tree, operand, query_left, query_right, node*2, left, middle, factor)
	apply_update(tree, operand, query_left, query_right, node*2+1, middle, right, factor)
	tree[node] = operand[node]*(tree[node*2]+tree[node*2+1])
}

query_sum :: proc "contextless" (tree, operand: [^]i64, query_left, query_right, node, left, right: int) -> i64 {
	if query_left <= left && right <= query_right do return tree[node]
	if query_right <= left || right <= query_left do return 0
	middle := left + (right-left)/2
	return operand[node]*(query_sum(tree, operand, query_left, query_right, node*2, left, middle)+
		query_sum(tree, operand, query_left, query_right, node*2+1, middle, right))
}

segment_tree_apply_benchmark :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	if input[0] < 1 || input[0] > MAX_LENGTH do return -1
	n := int(input[0])
	if length < c.size_t(n+2) do return -1
	operation_value := input[n+1]
	if operation_value < 0 || operation_value > MAX_OPERATIONS do return -1
	operation_count := int(operation_value)
	if length != c.size_t(n+2+4*operation_count) || length > MAX_VALID_INPUT_LENGTH do return -1
	base := 1
	for base < n { base <<= 1 }
	var tree: [MAX_TREE_NODES]i64
	var operand: [MAX_TREE_NODES]i64
	for index in 0..<MAX_TREE_NODES { operand[index] = 1 }
	for index in 0 ..< n {
		value := input[index+1]
		if value < -1 || value > 1 do return -1
		tree[base+index] = value
	}
	for node := base-1; node > 0; node -= 1 { tree[node] = tree[node*2]+tree[node*2+1] }
	checksum := i64(0)
	for operation in 0 ..< operation_count {
		offset := n+2+4*operation
		opcode, left, right, argument := input[offset], input[offset+1], input[offset+2], input[offset+3]
		if left < 0 || left > right || right >= i64(n) do return -1
		query_left, query_right := int(left), int(right+1)
		if opcode == 0 {
			if argument < -2 || argument > 2 do return -1
			apply_update(&tree[0], &operand[0], query_left, query_right, 1, 0, base, argument)
		} else if opcode == 1 {
			if argument != 0 do return -1
			result := query_sum(&tree[0], &operand[0], query_left, query_right, 1, 0, base)
			checksum += i64(operation+1)*(result+CHECKSUM_OFFSET)
		} else { return -1 }
	}
	return checksum
}
