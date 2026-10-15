package same_trees_check

import "core:c"

MAX_NODE_COUNT :: 1023

Tree_View :: struct {
	count: int,
	root: i64,
	rows_offset: int,
}

parse_tree :: proc "contextless" (input: [^]i64, length: int, offset: ^int, tree: ^Tree_View) -> bool {
	if offset^ > length || length - offset^ < 2 do return false
	count_value, root := input[offset^], input[offset^ + 1]
	if count_value < 0 || count_value > MAX_NODE_COUNT do return false
	count := int(count_value)
	rows_offset := offset^ + 2
	if count > (length - rows_offset) / 3 do return false
	tree^ = Tree_View{count = count, root = root, rows_offset = rows_offset}
	offset^ = rows_offset + 3 * count
	return true
}

valid_tree :: proc "contextless" (input: [^]i64, tree: Tree_View) -> bool {
	if tree.count == 0 do return tree.root == -1
	if tree.root < 0 || u64(tree.root) >= u64(tree.count) do return false
	parents: [MAX_NODE_COUNT]int
	for index := 0; index < tree.count; index += 1 { parents[index] = 0 }
	for index := 0; index < tree.count; index += 1 {
		row := tree.rows_offset + 3 * index
		value, left, right := input[row], input[row + 1], input[row + 2]
		if value < -2147483648 || value > 2147483647 || left < -1 || right < -1 ||
			(left >= 0 && u64(left) >= u64(tree.count)) || (right >= 0 && u64(right) >= u64(tree.count)) do return false
		if left >= 0 { parents[int(left)] += 1; if parents[int(left)] > 1 do return false }
		if right >= 0 { parents[int(right)] += 1; if parents[int(right)] > 1 do return false }
	}
	root := int(tree.root)
	for index := 0; index < tree.count; index += 1 {
		expected := 1
		if index == root { expected = 0 }
		if parents[index] != expected do return false
	}
	queue: [MAX_NODE_COUNT]int
	seen: [MAX_NODE_COUNT]bool
	for index := 0; index < tree.count; index += 1 { seen[index] = false }
	head, tail := 0, 1
	queue[0] = root
	for head < tail {
		index := queue[head]
		head += 1
		if seen[index] do return false
		seen[index] = true
		row := tree.rows_offset + 3 * index
		left, right := input[row + 1], input[row + 2]
		if left >= 0 { queue[tail] = int(left); tail += 1 }
		if right >= 0 { queue[tail] = int(right); tail += 1 }
	}
	return tail == tree.count
}

trees_equal :: proc "contextless" (input: [^]i64, first, second: Tree_View) -> i64 {
	if first.root == -1 || second.root == -1 {
		if first.root == second.root do return 1
		return 0
	}
	queue1, queue2: [MAX_NODE_COUNT]int
	head, tail := 0, 1
	queue1[0], queue2[0] = int(first.root), int(second.root)
	for head < tail {
		index1, index2 := queue1[head], queue2[head]
		head += 1
		row1, row2 := first.rows_offset + 3 * index1, second.rows_offset + 3 * index2
		left1, right1 := input[row1 + 1], input[row1 + 2]
		left2, right2 := input[row2 + 1], input[row2 + 2]
		if input[row1] != input[row2] || (left1 == -1) != (left2 == -1) || (right1 == -1) != (right2 == -1) do return 0
		if left1 >= 0 { queue1[tail] = int(left1); queue2[tail] = int(left2); tail += 1 }
		if right1 >= 0 { queue1[tail] = int(right1); queue2[tail] = int(right2); tail += 1 }
	}
	return 1
}

@(export)
same_trees_check :: proc "contextless" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 4 + 3 * MAX_NODE_COUNT do return -1
	input_length := int(length)
	offset := 0
	first, second: Tree_View
	if !parse_tree(input, input_length, &offset, &first) ||
		!parse_tree(input, input_length, &offset, &second) || offset != input_length ||
		first.count + second.count > MAX_NODE_COUNT || !valid_tree(input, first) || !valid_tree(input, second) do return -1
	return trees_equal(input, first, second)
}
