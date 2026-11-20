package mo_2d_rectangle_frequency_square

import "core:c"

MAX_SIDE :: 8
MAX_QUERIES :: 32
MAX_VALUE :: 7
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(195)

Rectangle_Query :: struct {
	top_block, left_block, bottom_block, right_block: int,
	top, left, bottom, right, ordinal: int,
}

query_before :: proc(a, b: Rectangle_Query) -> bool {
	if a.top_block != b.top_block do return a.top_block < b.top_block
	if a.left_block != b.left_block do return a.left_block < b.left_block
	if a.bottom_block != b.bottom_block do return a.bottom_block < b.bottom_block
	if a.right_block != b.right_block do return a.right_block < b.right_block
	if a.top != b.top do return a.top < b.top
	if a.left != b.left do return a.left < b.left
	if a.bottom != b.bottom do return a.bottom < b.bottom
	if a.right != b.right do return a.right < b.right
	return a.ordinal < b.ordinal
}

add_value :: proc(value: int, frequencies: ^[MAX_VALUE + 1]i64, statistic: ^i64) {
	old_frequency := frequencies[value]
	statistic^ += 2 * old_frequency + 1
	frequencies[value] = old_frequency + 1
}

remove_value :: proc(value: int, frequencies: ^[MAX_VALUE + 1]i64, statistic: ^i64) {
	old_frequency := frequencies[value]
	statistic^ += 1 - 2 * old_frequency
	frequencies[value] = old_frequency - 1
}

@(export)
mo_2d_rectangle_frequency_square :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	side_value, query_count_value := input[0], input[1]
	if side_value < 1 || side_value > MAX_SIDE || query_count_value < 0 || query_count_value > MAX_QUERIES do return -1
	side, query_count := int(side_value), int(query_count_value)
	matrix_end := 2 + side * side
	if length != c.size_t(matrix_end + 4 * query_count) do return -1

	var matrix: [MAX_SIDE * MAX_SIDE]int
	for position := 0; position < side * side; position += 1 {
		value := input[2 + position]
		if value < 0 || value > MAX_VALUE do return -1
		matrix[position] = int(value)
	}

	var queries: [MAX_QUERIES]Rectangle_Query
	for ordinal := 0; ordinal < query_count; ordinal += 1 {
		offset := matrix_end + 4 * ordinal
		top_value, left_value := input[offset], input[offset+1]
		bottom_value, right_value := input[offset+2], input[offset+3]
		if top_value < 0 || bottom_value < top_value || bottom_value >= side_value ||
			left_value < 0 || right_value < left_value || right_value >= side_value do return -1
		top, left := int(top_value), int(left_value)
		bottom, right := int(bottom_value), int(right_value)
		queries[ordinal] = Rectangle_Query{top = top, left = left, bottom = bottom, right = right, ordinal = ordinal}
	}

	block_size := 0
	side_fourth := side * side * side * side
	for candidate := 1; candidate <= side; candidate += 1 {
		if query_count * candidate * candidate * candidate * candidate <= side_fourth do block_size = candidate
	}
	if block_size == 0 do block_size = 1
	for ordinal := 0; ordinal < query_count; ordinal += 1 {
		queries[ordinal].top_block = queries[ordinal].top / block_size
		queries[ordinal].left_block = queries[ordinal].left / block_size
		queries[ordinal].bottom_block = queries[ordinal].bottom / block_size
		queries[ordinal].right_block = queries[ordinal].right / block_size
	}
	for i := 1; i < query_count; i += 1 {
		current := queries[i]
		position := i
		for position > 0 && query_before(current, queries[position-1]) {
			queries[position] = queries[position-1]
			position -= 1
		}
		queries[position] = current
	}

	var answers: [MAX_QUERIES]i64
	if query_count == 0 do return 0
	var frequencies: [MAX_VALUE + 1]i64
	statistic := i64(0)
	top, left := queries[0].top, queries[0].left
	bottom, right := queries[0].bottom, queries[0].right
	for row := top; row <= bottom; row += 1 {
		for column := left; column <= right; column += 1 { add_value(matrix[row*side+column], &frequencies, &statistic) }
	}
	answers[queries[0].ordinal] = statistic

	for sorted_index := 1; sorted_index < query_count; sorted_index += 1 {
		query := queries[sorted_index]
		for top > query.top {
			top -= 1
			for column := left; column <= right; column += 1 { add_value(matrix[top*side+column], &frequencies, &statistic) }
		}
		for bottom < query.bottom {
			bottom += 1
			for column := left; column <= right; column += 1 { add_value(matrix[bottom*side+column], &frequencies, &statistic) }
		}
		for left > query.left {
			left -= 1
			for row := top; row <= bottom; row += 1 { add_value(matrix[row*side+left], &frequencies, &statistic) }
		}
		for right < query.right {
			right += 1
			for row := top; row <= bottom; row += 1 { add_value(matrix[row*side+right], &frequencies, &statistic) }
		}
		for top < query.top {
			for column := left; column <= right; column += 1 { remove_value(matrix[top*side+column], &frequencies, &statistic) }
			top += 1
		}
		for bottom > query.bottom {
			for column := left; column <= right; column += 1 { remove_value(matrix[bottom*side+column], &frequencies, &statistic) }
			bottom -= 1
		}
		for left < query.left {
			for row := top; row <= bottom; row += 1 { remove_value(matrix[row*side+left], &frequencies, &statistic) }
			left += 1
		}
		for right > query.right {
			for row := top; row <= bottom; row += 1 { remove_value(matrix[row*side+right], &frequencies, &statistic) }
			right -= 1
		}
		answers[query.ordinal] = statistic
	}

	checksum := i64(0)
	for ordinal := 0; ordinal < query_count; ordinal += 1 { checksum += i64(ordinal+1) * answers[ordinal] }
	return checksum
}
