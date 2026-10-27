package rle_lcs_block_dp

import "core:c"

// Run-length-native LCS by run-pair blocks and boundary propagation.
@(export)
rle_lcs_block_dp :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed == nil || length < 4 || length > 18 do return -1
	left_count_value := packed[0]
	if left_count_value < 1 || left_count_value > 4 do return -1
	left_count := int(left_count_value)
	right_count_index := 1 + 2 * left_count
	if right_count_index >= int(length) do return -1
	right_count_value := packed[right_count_index]
	if right_count_value < 1 || right_count_value > 4 ||
		int(length) != right_count_index + 1 + 2 * int(right_count_value) do return -1
	right_count := int(right_count_value)
	left_symbol: [4]i64
	left_size: [4]i64
	right_symbol: [4]i64
	right_size: [4]i64
	left_total, right_total := 0, 0
	for run := 0; run < left_count; run += 1 {
		symbol, size := packed[1+2*run], packed[2+2*run]
		if symbol < 0 || symbol > 3 || size < 1 || size > 8 do return -1
		left_total += int(size)
		if left_total > 16 do return -1
		left_symbol[run], left_size[run] = symbol, size
	}
	for run := 0; run < right_count; run += 1 {
		symbol := packed[right_count_index+1+2*run]
		size := packed[right_count_index+2+2*run]
		if symbol < 0 || symbol > 3 || size < 1 || size > 8 do return -1
		right_total += int(size)
		if right_total > 16 do return -1
		right_symbol[run], right_size[run] = symbol, size
	}
	bottom: [4][9]i64
	next_bottom: [4][9]i64
	for i := 0; i < left_count; i += 1 {
		left_boundary: [9]i64
		for j := 0; j < right_count; j += 1 {
			rows, columns := int(left_size[i]), int(right_size[j])
			previous: [9]i64
			current: [9]i64
			right_boundary: [9]i64
			for column := 0; column <= columns; column += 1 { previous[column] = bottom[j][column] }
			right_boundary[0] = previous[columns]
			for row := 1; row <= rows; row += 1 {
				current[0] = left_boundary[row]
				for column := 1; column <= columns; column += 1 {
					if left_symbol[i] == right_symbol[j] {
						current[column] = previous[column-1] + 1
					} else if previous[column] > current[column-1] {
						current[column] = previous[column]
					} else {
						current[column] = current[column-1]
					}
				}
				right_boundary[row] = current[columns]
				for column := 0; column <= columns; column += 1 { previous[column] = current[column] }
			}
			for column := 0; column <= columns; column += 1 { next_bottom[j][column] = previous[column] }
			for row := 0; row <= rows; row += 1 { left_boundary[row] = right_boundary[row] }
		}
		for j := 0; j < right_count; j += 1 {
			for column := 0; column <= int(right_size[j]); column += 1 { bottom[j][column] = next_bottom[j][column] }
		}
	}
	return bottom[right_count-1][int(right_size[right_count-1])]
}
