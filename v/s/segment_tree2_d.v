module segment_tree2_d

const max_rows = 16
const max_columns = 16
const max_operations = 256
const max_tree_side = 64
const max_parseable_input_length = 1284
const checksum_offset = i64(256001)

fn set_column(mut tree [max_tree_side][max_tree_side]i64, row_node int, column_base int, column int, value i64) {
	mut node := column_base + column
	tree[row_node][node] = value
	node >>= 1
	for node > 0 {
		tree[row_node][node] = tree[row_node][node << 1] + tree[row_node][(node << 1) | 1]
		node >>= 1
	}
}

fn query_columns(tree [max_tree_side][max_tree_side]i64, row_node int, column_base int, left int, right int) i64 {
	mut first := left + column_base
	mut last := right + column_base
	mut sum := i64(0)
	for first < last {
		if first & 1 != 0 { sum += tree[row_node][first]; first++ }
		if last & 1 != 0 { last--; sum += tree[row_node][last] }
		first >>= 1
		last >>= 1
	}
	return sum
}

fn assign_point(mut tree [max_tree_side][max_tree_side]i64, row_base int, column_base int, row int, column int, value i64) {
	row_leaf := row_base + row
	set_column(mut tree, row_leaf, column_base, column, value)
	mut row_node := row_leaf >> 1
	for row_node > 0 {
		left_value := tree[row_node << 1][column_base + column]
		right_value := tree[(row_node << 1) | 1][column_base + column]
		set_column(mut tree, row_node, column_base, column, left_value + right_value)
		row_node >>= 1
	}
}

fn query_rectangle(tree [max_tree_side][max_tree_side]i64, row_base int, column_base int, top int, bottom int, left int, right int) i64 {
	mut first := top + row_base
	mut last := bottom + row_base
	mut sum := i64(0)
	for first < last {
		if first & 1 != 0 { sum += query_columns(tree, first, column_base, left, right); first++ }
		if last & 1 != 0 { last--; sum += query_columns(tree, last, column_base, left, right) }
		first >>= 1
		last >>= 1
	}
	return sum
}

@[export: 'segment_tree2_d_benchmark']
pub fn segment_tree2_d_benchmark(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 3 || length > usize(max_parseable_input_length) { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_rows || input[1] < 1 || input[1] > max_columns || input[2] < 0 || input[2] > max_operations { return -1 }
		rows, columns, operation_count := int(input[0]), int(input[1]), int(input[2])
		if length != usize(3 + 5 * operation_count) || length > 1283 { return -1 }
		mut row_base, mut column_base := 1, 1
		for row_base < rows { row_base <<= 1 }
		for column_base < columns { column_base <<= 1 }
		mut tree := [max_tree_side][max_tree_side]i64{}
		mut checksum := i64(0)
		for operation in 0 .. operation_count {
			offset := 3 + 5 * operation
			opcode, first, second := input[offset], input[offset + 1], input[offset + 2]
			third, fourth := input[offset + 3], input[offset + 4]
			if opcode == 0 {
				if first < 0 || first >= i64(rows) || second < 0 || second >= i64(columns) || third < -1000 || third > 1000 || fourth != 0 { return -1 }
				assign_point(mut tree, row_base, column_base, int(first), int(second), third)
			} else if opcode == 1 {
				if first < 0 || first > second || second > i64(rows) || third < 0 || third > fourth || fourth > i64(columns) { return -1 }
				result := query_rectangle(tree, row_base, column_base, int(first), int(second), int(third), int(fourth))
				checksum += i64(operation + 1) * (result + checksum_offset)
			} else { return -1 }
		}
		return checksum
	}
}
