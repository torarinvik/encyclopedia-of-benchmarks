module same_trees_check

const max_node_count = 1023

struct TreeView {
	count int
	root i64
	rows_offset int
}

fn parse_tree(input &i64, length int, mut offset int, mut tree TreeView) bool {
	if offset > length || length - offset < 2 { return false }
	count_value := unsafe { input[offset] }
	root := unsafe { input[offset + 1] }
	if count_value < 0 || count_value > max_node_count { return false }
	count := int(count_value)
	rows_offset := offset + 2
	if count > (length - rows_offset) / 3 { return false }
	tree = TreeView{count: count, root: root, rows_offset: rows_offset}
	offset = rows_offset + 3 * count
	return true
}

fn valid_tree(input &i64, tree TreeView) bool {
	if tree.count == 0 { return tree.root == -1 }
	if tree.root < 0 || u64(tree.root) >= u64(tree.count) { return false }
	mut parents := [max_node_count]int{}
	for index in 0 .. tree.count {
		row := tree.rows_offset + 3 * index
		value := unsafe { input[row] }
		left := unsafe { input[row + 1] }
		right := unsafe { input[row + 2] }
		if value < -2147483648 || value > 2147483647 || left < -1 || right < -1 ||
			(left >= 0 && u64(left) >= u64(tree.count)) || (right >= 0 && u64(right) >= u64(tree.count)) { return false }
		if left >= 0 { parents[int(left)]++; if parents[int(left)] > 1 { return false } }
		if right >= 0 { parents[int(right)]++; if parents[int(right)] > 1 { return false } }
	}
	for index in 0 .. tree.count {
		expected := 1
		if index == int(tree.root) { expected = 0 }
		if parents[index] != expected { return false }
	}
	mut queue := [max_node_count]int{}
	mut seen := [max_node_count]bool{}
	mut head := 0
	mut tail := 1
	queue[0] = int(tree.root)
	for head < tail {
		index := queue[head]
		head++
		if seen[index] { return false }
		seen[index] = true
		row := tree.rows_offset + 3 * index
		left := unsafe { input[row + 1] }
		right := unsafe { input[row + 2] }
		if left >= 0 { queue[tail] = int(left); tail++ }
		if right >= 0 { queue[tail] = int(right); tail++ }
	}
	return tail == tree.count
}

fn trees_equal(input &i64, first TreeView, second TreeView) i64 {
	if first.root == -1 || second.root == -1 {
		if first.root == second.root { return 1 }
		return 0
	}
	mut queue1 := [max_node_count]int{}
	mut queue2 := [max_node_count]int{}
	mut head := 0
	mut tail := 1
	queue1[0] = int(first.root)
	queue2[0] = int(second.root)
	for head < tail {
		index1 := queue1[head]
		index2 := queue2[head]
		head++
		row1 := first.rows_offset + 3 * index1
		row2 := second.rows_offset + 3 * index2
		value1 := unsafe { input[row1] }
		value2 := unsafe { input[row2] }
		left1 := unsafe { input[row1 + 1] }
		right1 := unsafe { input[row1 + 2] }
		left2 := unsafe { input[row2 + 1] }
		right2 := unsafe { input[row2 + 2] }
		if value1 != value2 || (left1 == -1) != (left2 == -1) || (right1 == -1) != (right2 == -1) { return 0 }
		if left1 >= 0 { queue1[tail] = int(left1); queue2[tail] = int(left2); tail++ }
		if right1 >= 0 { queue1[tail] = int(right1); queue2[tail] = int(right2); tail++ }
	}
	return 1
}

@[export: 'same_trees_check']
pub fn same_trees_check(input &i64, length usize) i64 {
	if length < 4 || length > 4 + 3 * max_node_count { return -1 }
	input_length := int(length)
	mut offset := 0
	mut first := TreeView{}
	mut second := TreeView{}
	if !parse_tree(input, input_length, mut offset, mut first) ||
		!parse_tree(input, input_length, mut offset, mut second) || offset != input_length ||
		first.count + second.count > max_node_count || !valid_tree(input, first) || !valid_tree(input, second) { return -1 }
	return trees_equal(input, first, second)
}
