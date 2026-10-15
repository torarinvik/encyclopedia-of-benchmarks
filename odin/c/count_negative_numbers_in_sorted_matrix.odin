package count_negative_numbers_in_sorted_matrix

import "core:c"

@(export)
count_negative_numbers_in_sorted_matrix :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 514 do return -1
	rows_value := input[0]
	columns_value := input[1]
	if rows_value < 1 || rows_value > 512 || columns_value < 1 || columns_value > 512 do return -1
	rows := int(rows_value)
	columns := int(columns_value)
	if rows * columns > 512 || length != c.size_t(2 + rows * columns) do return -1

	nonnegative := 0
	bound := columns
	for row := 0; row < rows; row += 1 {
		left := 0
		right := bound
		for left < right {
			middle := left + (right - left) / 2
			value := input[2 + row * columns + middle]
			if value >= 0 { left = middle + 1 } else { right = middle }
		}
		bound = left
		nonnegative += bound
	}
	return i64(rows * columns - nonnegative)
}
