package suffix_balanced_tree

import "core:c"

MAX_TEXT :: 32
MAX_INPUT :: 33
TAG_LIMIT :: u64(1) << 62

Tree :: struct {
	text: [MAX_TEXT]i64,
	left: [MAX_TEXT]int,
	right: [MAX_TEXT]int,
	size: [MAX_TEXT]int,
	tag: [MAX_TEXT]u64,
	buffer: [MAX_TEXT]int,
	answer: [MAX_TEXT]int,
	buffered: int,
}

node_size :: proc "contextless" (tree: ^Tree, node: int) -> int {
	if node < 0 do return 0
	return tree^.size[node]
}
suffix_less :: proc "contextless" (tree: ^Tree, x, y, n: int) -> bool {
	if tree^.text[x] != tree^.text[y] do return tree^.text[x] < tree^.text[y]
	next_x := if x + 1 < n then tree^.tag[x + 1] else u64(0)
	next_y := if y + 1 < n then tree^.tag[y + 1] else u64(0)
	return next_x < next_y
}
flatten :: proc "contextless" (tree: ^Tree, root: int) {
	if root < 0 do return
	flatten(tree, tree^.left[root])
	tree^.buffer[tree^.buffered] = root
	tree^.buffered += 1
	flatten(tree, tree^.right[root])
}
build_balanced :: proc "contextless" (tree: ^Tree, lo, hi: int, low, high: u64) -> int {
	if lo >= hi do return -1
	mid := lo + (hi - lo) / 2
	root := tree^.buffer[mid]
	tag := low + (high - low) / 2
	tree^.tag[root] = tag
	tree^.left[root] = build_balanced(tree, lo, mid, low, tag)
	tree^.right[root] = build_balanced(tree, mid + 1, hi, tag, high)
	tree^.size[root] = 1 + node_size(tree, tree^.left[root]) + node_size(tree, tree^.right[root])
	return root
}
rebuild :: proc "contextless" (tree: ^Tree, root: int, low, high: u64) -> int {
	tree^.buffered = 0
	flatten(tree, root)
	return build_balanced(tree, 0, tree^.buffered, low, high)
}
insert_suffix :: proc "contextless" (tree: ^Tree, root, pos, n: int, low, high: u64) -> int {
	if root < 0 {
		tree^.left[pos] = -1
		tree^.right[pos] = -1
		tree^.size[pos] = 1
		tree^.tag[pos] = low + (high - low) / 2
		return pos
	}
	middle := tree^.tag[root]
	if suffix_less(tree, pos, root, n) {
		child := tree^.left[root]
		inserted := insert_suffix(tree, child, pos, n, low, middle)
		tree^.left[root] = inserted
	} else {
		child := tree^.right[root]
		inserted := insert_suffix(tree, child, pos, n, middle, high)
		tree^.right[root] = inserted
	}
	left_size := node_size(tree, tree^.left[root])
	right_size := node_size(tree, tree^.right[root])
	tree^.size[root] = 1 + left_size + right_size
	heavy := max(left_size, right_size)
	if 4 * heavy >= 3 * tree^.size[root] do return rebuild(tree, root, low, high)
	return root
}
inorder :: proc "contextless" (tree: ^Tree, root: int, count: ^int) {
	if root < 0 do return
	inorder(tree, tree^.left[root], count)
	tree^.answer[count^] = root
	count^ += 1
	inorder(tree, tree^.right[root], count)
}
store_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
suffix_balanced_tree :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT do return -1
	nv := input[0]
	if nv < 0 || nv > MAX_TEXT || length != c.size_t(1 + nv) do return -1
	n := int(nv)
	for i := 0; i < n; i += 1 { if input[1 + i] < 0 || input[1 + i] > 255 do return -1 }
	required := 8 * n
	if output == nil || capacity < c.size_t(required) do return -2
	tree: Tree
	for i := 0; i < n; i += 1 { tree.text[i] = input[1 + i] }
	root := -1
	for pos := n - 1; pos >= 0; pos -= 1 { root = insert_suffix(&tree, root, pos, n, 0, TAG_LIMIT) }
	count := 0
	inorder(&tree, root, &count)
	for i := 0; i < count; i += 1 { store_le(output, 8 * i, i64(tree.answer[i])) }
	return i64(required)
}
