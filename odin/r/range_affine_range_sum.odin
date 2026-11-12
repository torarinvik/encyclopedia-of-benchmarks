package range_affine_range_sum

import "core:c"

MODULUS :: i64(998244353)
MAX_LENGTH :: 64
MAX_OPERATIONS :: 64
TREE_NODES :: 256
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(387)

Affine_Tree :: struct {
	sum: [TREE_NODES]i64,
	lazy_mul: [TREE_NODES]i64,
	lazy_add: [TREE_NODES]i64,
}

apply :: proc "contextless" (tree: ^Affine_Tree, node, length: int, a, b: i64) {
	tree.sum[node] = (a * tree.sum[node] + b * i64(length)) % MODULUS
	tree.lazy_mul[node] = (a * tree.lazy_mul[node]) % MODULUS
	tree.lazy_add[node] = (a * tree.lazy_add[node] + b) % MODULUS
}

push :: proc "contextless" (tree: ^Affine_Tree, node, low, high: int) {
	if high - low <= 1 || (tree.lazy_mul[node] == 1 && tree.lazy_add[node] == 0) do return
	middle := low + (high-low)/2
	a, b := tree.lazy_mul[node], tree.lazy_add[node]
	apply(tree, node*2, middle-low, a, b)
	apply(tree, node*2+1, high-middle, a, b)
	tree.lazy_mul[node] = 1
	tree.lazy_add[node] = 0
}

build :: proc "contextless" (tree: ^Affine_Tree, values: [^]i64, node, low, high: int) {
	if high-low == 1 { tree.sum[node] = values[low]; return }
	middle := low + (high-low)/2
	build(tree, values, node*2, low, middle)
	build(tree, values, node*2+1, middle, high)
	tree.sum[node] = (tree.sum[node*2] + tree.sum[node*2+1]) % MODULUS
}

update :: proc "contextless" (tree: ^Affine_Tree, ql, qr, node, low, high: int, a, b: i64) {
	if ql <= low && high <= qr { apply(tree, node, high-low, a, b); return }
	if qr <= low || high <= ql do return
	push(tree, node, low, high)
	middle := low + (high-low)/2
	update(tree, ql, qr, node*2, low, middle, a, b)
	update(tree, ql, qr, node*2+1, middle, high, a, b)
	tree.sum[node] = (tree.sum[node*2] + tree.sum[node*2+1]) % MODULUS
}

query :: proc "contextless" (tree: ^Affine_Tree, ql, qr, node, low, high: int) -> i64 {
	if ql <= low && high <= qr do return tree.sum[node]
	if qr <= low || high <= ql do return 0
	push(tree, node, low, high)
	middle := low + (high-low)/2
	return (query(tree, ql, qr, node*2, low, middle) + query(tree, ql, qr, node*2+1, middle, high)) % MODULUS
}

@(export)
range_affine_range_sum_benchmark :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	if input[0] < 1 || input[0] > i64(MAX_LENGTH) do return -1
	n := int(input[0])
	if length < c.size_t(n+2) do return -1
	values: [MAX_LENGTH]i64
	for i in 0..<n {
		if input[i+1] < 0 || input[i+1] >= MODULUS do return -1
		values[i] = input[i+1]
	}
	if input[n+1] < 1 || input[n+1] > i64(MAX_OPERATIONS) do return -1
	operation_count := int(input[n+1])
	var tree: Affine_Tree
	for i in 0..<TREE_NODES { tree.lazy_mul[i] = 1 }
	build(&tree, &values[0], 1, 0, n)
	cursor := n+2
	checksum := i64(0)
	for operation in 0..<operation_count {
		if cursor >= int(length) do return -1
		opcode := input[cursor]
		cursor += 1
		if opcode == 0 {
			if cursor+4 > int(length) do return -1
			left, right, a, b := input[cursor], input[cursor+1], input[cursor+2], input[cursor+3]
			cursor += 4
			if left < 0 || left >= right || right > i64(n) || a < 1 || a >= MODULUS || b < 0 || b >= MODULUS do return -1
			update(&tree, int(left), int(right), 1, 0, n, a, b)
		} else if opcode == 1 {
			if cursor+2 > int(length) do return -1
			left, right := input[cursor], input[cursor+1]
			cursor += 2
			if left < 0 || left >= right || right > i64(n) do return -1
			result := query(&tree, int(left), int(right), 1, 0, n)
			checksum += i64(operation+1) * (result + MODULUS)
		} else { return -1 }
	}
	if cursor == int(length) do return checksum
	return -1
}
