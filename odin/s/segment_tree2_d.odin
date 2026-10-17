package segment_tree2_d

import "core:c"

MAX_ROWS :: 16
MAX_COLUMNS :: 16
MAX_OPERATIONS :: 256
MAX_TREE_SIDE :: 64
MAX_VALID_INPUT_LENGTH :: c.size_t(1283)
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(1284)
CHECKSUM_OFFSET :: i64(256001)

set_column :: proc "contextless" (tree: [^][MAX_TREE_SIDE]i64, row_node, column_base, column: int, value: i64) {
	node := column_base + column
	tree[row_node][node] = value
	node >>= 1
	for node > 0 {
		tree[row_node][node] = tree[row_node][node<<1] + tree[row_node][(node<<1)|1]
		node >>= 1
	}
}

query_columns :: proc "contextless" (tree: [^][MAX_TREE_SIDE]i64, row_node, column_base, left, right: int) -> i64 {
	first, last := left+column_base, right+column_base
	sum := i64(0)
	for first < last {
		if first&1 != 0 { sum += tree[row_node][first]; first += 1 }
		if last&1 != 0 { last -= 1; sum += tree[row_node][last] }
		first >>= 1
		last >>= 1
	}
	return sum
}

assign_point :: proc "contextless" (tree: [^][MAX_TREE_SIDE]i64, row_base, column_base, row, column: int, value: i64) {
	row_leaf := row_base + row
	set_column(tree, row_leaf, column_base, column, value)
	row_node := row_leaf >> 1
	for row_node > 0 {
		left_value := tree[row_node<<1][column_base+column]
		right_value := tree[(row_node<<1)|1][column_base+column]
		set_column(tree, row_node, column_base, column, left_value+right_value)
		row_node >>= 1
	}
}

query_rectangle :: proc "contextless" (tree: [^][MAX_TREE_SIDE]i64, row_base, column_base, top, bottom, left, right: int) -> i64 {
	first, last := top+row_base, bottom+row_base
	sum := i64(0)
	for first < last {
		if first&1 != 0 { sum += query_columns(tree, first, column_base, left, right); first += 1 }
		if last&1 != 0 { last -= 1; sum += query_columns(tree, last, column_base, left, right) }
		first >>= 1
		last >>= 1
	}
	return sum
}

segment_tree2_d_benchmark :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	if input[0] < 1 || input[0] > MAX_ROWS || input[1] < 1 || input[1] > MAX_COLUMNS do return -1
	if input[2] < 0 || input[2] > MAX_OPERATIONS do return -1
	rows, columns, operation_count := int(input[0]), int(input[1]), int(input[2])
	if length != c.size_t(3+5*operation_count) || length > MAX_VALID_INPUT_LENGTH do return -1
	row_base, column_base := 1, 1
	for row_base < rows { row_base <<= 1 }
	for column_base < columns { column_base <<= 1 }
	var tree: [MAX_TREE_SIDE][MAX_TREE_SIDE]i64
	checksum := i64(0)
	for operation in 0 ..< operation_count {
		offset := 3+5*operation
		opcode, first, second := input[offset], input[offset+1], input[offset+2]
		third, fourth := input[offset+3], input[offset+4]
		if opcode == 0 {
			if first < 0 || first >= i64(rows) || second < 0 || second >= i64(columns) || third < -1000 || third > 1000 || fourth != 0 do return -1
			assign_point(&tree[0], row_base, column_base, int(first), int(second), third)
		} else if opcode == 1 {
			if first < 0 || first > second || second > i64(rows) || third < 0 || third > fourth || fourth > i64(columns) do return -1
			result := query_rectangle(&tree[0], row_base, column_base, int(first), int(second), int(third), int(fourth))
			checksum += i64(operation+1)*(result+CHECKSUM_OFFSET)
		} else { return -1 }
	}
	return checksum
}
