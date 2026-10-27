package rle_levenshtein_block_dp

import "core:c"

// Run-length-native unit-cost edit distance by run-pair blocks.
@(export)
rle_levenshtein_block_dp :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed == nil || length < 4 || length > 18 || packed[0] < 1 || packed[0] > 4 do return -1
	left_count := int(packed[0])
	right_index := 1 + 2*left_count
	if right_index >= int(length) || packed[right_index] < 1 || packed[right_index] > 4 do return -1
	right_count := int(packed[right_index])
	if int(length) != right_index + 1 + 2*right_count do return -1
	left_symbol: [4]i64
	left_size: [4]int
	right_symbol: [4]i64
	right_size: [4]int
	left_total, right_total := 0, 0
	for run := 0; run < left_count; run += 1 {
		symbol, size := packed[1+2*run], packed[2+2*run]
		if symbol < 0 || symbol > 3 || size < 1 || size > 8 do return -1
		left_total += int(size); if left_total > 16 do return -1
		left_symbol[run], left_size[run] = symbol, int(size)
	}
	for run := 0; run < right_count; run += 1 {
		symbol, size := packed[right_index+1+2*run], packed[right_index+2+2*run]
		if symbol < 0 || symbol > 3 || size < 1 || size > 8 do return -1
		right_total += int(size); if right_total > 16 do return -1
		right_symbol[run], right_size[run] = symbol, int(size)
	}
	bottom: [4][9]i64
	next_bottom: [4][9]i64
	right_prefix := 0
	for j := 0; j < right_count; j += 1 {
		for column := 0; column <= right_size[j]; column += 1 { bottom[j][column] = i64(right_prefix+column) }
		right_prefix += right_size[j]
	}
	left_prefix := 0
	for i := 0; i < left_count; i += 1 {
		rows := left_size[i]
		left_boundary: [9]i64
		for row := 0; row <= rows; row += 1 { left_boundary[row] = i64(left_prefix+row) }
		for j := 0; j < right_count; j += 1 {
			columns := right_size[j]
			previous: [9]i64
			current: [9]i64
			right_boundary: [9]i64
			for column := 0; column <= columns; column += 1 { previous[column] = bottom[j][column] }
			right_boundary[0] = previous[columns]
			substitution := i64(0); if left_symbol[i] != right_symbol[j] { substitution = 1 }
			for row := 1; row <= rows; row += 1 {
				current[0] = left_boundary[row]
				for column := 1; column <= columns; column += 1 {
					deletion, insertion, replace := previous[column]+1, current[column-1]+1, previous[column-1]+substitution
					best := deletion; if insertion < best { best = insertion }; if replace < best { best = replace }
					current[column] = best
				}
				right_boundary[row] = current[columns]
				for column := 0; column <= columns; column += 1 { previous[column] = current[column] }
			}
			for column := 0; column <= columns; column += 1 { next_bottom[j][column] = previous[column] }
			for row := 0; row <= rows; row += 1 { left_boundary[row] = right_boundary[row] }
		}
		for j := 0; j < right_count; j += 1 {
			for column := 0; column <= right_size[j]; column += 1 { bottom[j][column] = next_bottom[j][column] }
		}
		left_prefix += rows
	}
	return bottom[right_count-1][right_size[right_count-1]]
}
