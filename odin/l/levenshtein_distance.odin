package levenshtein_distance

import "core:c"

// Unit-cost Levenshtein distance over two ASCII byte sequences.
@(export)
levenshtein_distance :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length < 2 do return -1
	left_length_value := values[0]
	right_length_value := values[1]
	if left_length_value < 0 || left_length_value > 255 || right_length_value < 0 || right_length_value > 255 do return -1
	left_length := c.size_t(left_length_value)
	right_length := c.size_t(right_length_value)
	if length != 2 + left_length + right_length do return -1
	left_start := c.size_t(2)
	right_start := left_start + left_length
	for index: c.size_t = 0; index < left_length; index += 1 {
		if values[left_start + index] < 0 || values[left_start + index] > 127 do return -1
	}
	for index: c.size_t = 0; index < right_length; index += 1 {
		if values[right_start + index] < 0 || values[right_start + index] > 127 do return -1
	}

	row: [256]i64
	for column: c.size_t = 0; column <= right_length; column += 1 {
		row[column] = i64(column)
	}
	for row_index: c.size_t = 1; row_index <= left_length; row_index += 1 {
		diagonal := row[0]
		row[0] = i64(row_index)
		for column: c.size_t = 1; column <= right_length; column += 1 {
			above := row[column]
			deletion := above + 1
			insertion := row[column - 1] + 1
			substitution := diagonal + i64(values[left_start + row_index - 1] != values[right_start + column - 1])
			best := min(deletion, insertion, substitution)
			row[column] = best
			diagonal = above
		}
	}
	return row[right_length]
}
