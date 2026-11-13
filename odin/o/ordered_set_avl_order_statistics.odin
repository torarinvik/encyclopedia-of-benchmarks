package ordered_set_avl_order_statistics

import "core:c"

MAX_ITEMS :: i64(32)
MAX_OPS :: i64(32)
MAX_KEY :: i64(1000)

Tree :: struct {
	key: [65]i64,
	height: [65]int,
	size: [65]int,
	left: [65]int,
	right: [65]int,
	used: int,
}

node_height :: proc(tree: ^Tree, node: int) -> int { if node == 0 do return 0; return tree.height[node] }
node_size :: proc(tree: ^Tree, node: int) -> int { if node == 0 do return 0; return tree.size[node] }

refresh :: proc(tree: ^Tree, node: int) {
	lh := node_height(tree, tree.left[node]); rh := node_height(tree, tree.right[node])
	if lh > rh { tree.height[node] = lh + 1 } else { tree.height[node] = rh + 1 }
	tree.size[node] = node_size(tree, tree.left[node]) + node_size(tree, tree.right[node]) + 1
}

rotate_right :: proc(tree: ^Tree, root: int) -> int {
	pivot := tree.left[root]
	tree.left[root] = tree.right[pivot]; tree.right[pivot] = root
	refresh(tree, root); refresh(tree, pivot)
	return pivot
}
rotate_left :: proc(tree: ^Tree, root: int) -> int {
	pivot := tree.right[root]
	tree.right[root] = tree.left[pivot]; tree.left[pivot] = root
	refresh(tree, root); refresh(tree, pivot)
	return pivot
}
rebalance :: proc(tree: ^Tree, root: int) -> int {
	refresh(tree, root)
	difference := node_height(tree, tree.left[root]) - node_height(tree, tree.right[root])
	if difference > 1 {
		child := tree.left[root]
		if node_height(tree, tree.left[child]) < node_height(tree, tree.right[child]) { tree.left[root] = rotate_left(tree, child) }
		return rotate_right(tree, root)
	}
	if difference < -1 {
		child := tree.right[root]
		if node_height(tree, tree.right[child]) < node_height(tree, tree.left[child]) { tree.right[root] = rotate_right(tree, child) }
		return rotate_left(tree, root)
	}
	return root
}

insert_key :: proc(tree: ^Tree, root: int, key: i64) -> int {
	if root == 0 {
		tree.used += 1
		node := tree.used
		tree.key[node] = key; tree.height[node] = 1; tree.size[node] = 1
		return node
	}
	if key < tree.key[root] { tree.left[root] = insert_key(tree, tree.left[root], key) }
	else if key > tree.key[root] { tree.right[root] = insert_key(tree, tree.right[root], key) }
	else { return root }
	return rebalance(tree, root)
}
minimum_node :: proc(tree: ^Tree, root_input: int) -> int {
	root := root_input
	for tree.left[root] != 0 { root = tree.left[root] }
	return root
}
erase_key :: proc(tree: ^Tree, root: int, key: i64) -> int {
	if root == 0 do return 0
	if key < tree.key[root] { tree.left[root] = erase_key(tree, tree.left[root], key) }
	else if key > tree.key[root] { tree.right[root] = erase_key(tree, tree.right[root], key) }
	else if tree.left[root] == 0 { return tree.right[root] }
	else if tree.right[root] == 0 { return tree.left[root] }
	else {
		next := minimum_node(tree, tree.right[root])
		tree.key[root] = tree.key[next]
		tree.right[root] = erase_key(tree, tree.right[root], tree.key[next])
	}
	return rebalance(tree, root)
}

kth :: proc(tree: ^Tree, root_input: int, rank_input: i64) -> i64 {
	if rank_input < 1 || rank_input > i64(node_size(tree, root_input)) do return -1
	root := root_input; rank := rank_input
	for root != 0 {
		left_count := i64(node_size(tree, tree.left[root]))
		if rank == left_count + 1 do return tree.key[root]
		if rank <= left_count { root = tree.left[root] } else { rank -= left_count + 1; root = tree.right[root] }
	}
	return -1
}
count_le :: proc(tree: ^Tree, root_input: int, key: i64) -> i64 {
	root := root_input; count := i64(0)
	for root != 0 {
		if tree.key[root] <= key { count += i64(node_size(tree, tree.left[root])) + 1; root = tree.right[root] }
		else { root = tree.left[root] }
	}
	return count
}
predecessor :: proc(tree: ^Tree, root_input: int, key: i64) -> i64 {
	root := root_input; answer := i64(-1)
	for root != 0 {
		if tree.key[root] <= key { answer = tree.key[root]; root = tree.right[root] }
		else { root = tree.left[root] }
	}
	return answer
}
successor :: proc(tree: ^Tree, root_input: int, key: i64) -> i64 {
	root := root_input; answer := i64(-1)
	for root != 0 {
		if tree.key[root] >= key { answer = tree.key[root]; root = tree.left[root] }
		else { root = tree.right[root] }
	}
	return answer
}

@(export)
ordered_set_avl_order_statistics :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 99 do return -1
	n, q := input[0], input[1]
	if n < 0 || n > MAX_ITEMS || q < 0 || q > MAX_OPS || length != c.size_t(2 + n + 2 * q) do return -1
	for i := i64(0); i < n; i += 1 {
		key := input[2 + i]
		if key < 0 || key > MAX_KEY || (i > 0 && input[1 + i] >= key) do return -1
	}
	for i := i64(0); i < q; i += 1 {
		op, key := input[2 + n + 2 * i], input[3 + n + 2 * i]
		if op < 0 || op > 5 || key < 0 || key > MAX_KEY || (op == 2 && key < 1) do return -1
	}
	tree := Tree{}
	root := 0
	for i := i64(0); i < n; i += 1 { root = insert_key(&tree, root, input[2 + i]) }
	checksum, query_index := i64(0), i64(0)
	for i := i64(0); i < q; i += 1 {
		op, key := input[2 + n + 2 * i], input[3 + n + 2 * i]
		if op == 0 { root = insert_key(&tree, root, key) }
		else if op == 1 { root = erase_key(&tree, root, key) }
		else {
			answer := if op == 2 { kth(&tree, root, key) } else if op == 3 { count_le(&tree, root, key) } else if op == 4 { predecessor(&tree, root, key) } else { successor(&tree, root, key) }
			query_index += 1; checksum += query_index * (answer + 1)
		}
	}
	return checksum
}
