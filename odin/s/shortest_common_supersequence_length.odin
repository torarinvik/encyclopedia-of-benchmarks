package shortest_common_supersequence_length

import "core:c"

// Return the shortest common supersequence length of two packed ASCII sequences.
@(export)
shortest_common_supersequence_length :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed == nil || length < 2 || length > 512 do return -1
	left_length := packed[0]
	right_length := packed[1]
	if left_length < 0 || left_length > 255 || right_length < 0 || right_length > 255 do return -1
	if length != c.size_t(2 + left_length + right_length) do return -1
	for index := c.size_t(0); index < c.size_t(left_length + right_length); index += 1 {
		if packed[2 + index] < 0 || packed[2 + index] > 127 do return -1
	}

	rows := int(left_length + 1)
	columns := int(right_length + 1)
	table: [65536]i64
	for i := 1; i < rows; i += 1 {
		for j := 1; j < columns; j += 1 {
			cell := i * columns + j
			if packed[1 + c.size_t(i)] == packed[1 + c.size_t(left_length) + c.size_t(j)] {
				table[cell] = table[(i - 1) * columns + j - 1] + 1
			} else {
				above := table[(i - 1) * columns + j]
				left := table[i * columns + j - 1]
				table[cell] = max(above, left)
			}
		}
	}
	return left_length + right_length - table[(rows - 1) * columns + columns - 1]
}
