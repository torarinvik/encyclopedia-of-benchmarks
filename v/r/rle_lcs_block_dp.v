module rle_lcs_block_dp

// Run-length-native LCS by run-pair blocks and boundary propagation.
@[export: 'rle_lcs_block_dp']
pub fn rle_lcs_block_dp(packed &i64, length usize) i64 {
	if length < 4 || length > 18 { return -1 }
	left_count_value := unsafe { packed[0] }
	if left_count_value < 1 || left_count_value > 4 { return -1 }
	left_count := int(left_count_value)
	right_count_index := 1 + 2 * left_count
	if right_count_index >= int(length) { return -1 }
	right_count_value := unsafe { packed[right_count_index] }
	if right_count_value < 1 || right_count_value > 4 || int(length) != right_count_index + 1 + 2 * int(right_count_value) { return -1 }
	right_count := int(right_count_value)
	mut left_symbol := [4]i64{}
	mut left_size := [4]int{}
	mut right_symbol := [4]i64{}
	mut right_size := [4]int{}
	mut left_total := 0
	mut right_total := 0
	for run in 0 .. left_count {
		symbol := unsafe { packed[1 + 2 * run] }
		size := unsafe { packed[2 + 2 * run] }
		if symbol < 0 || symbol > 3 || size < 1 || size > 8 { return -1 }
		left_total += int(size)
		if left_total > 16 { return -1 }
		left_symbol[run], left_size[run] = symbol, int(size)
	}
	for run in 0 .. right_count {
		symbol := unsafe { packed[right_count_index + 1 + 2 * run] }
		size := unsafe { packed[right_count_index + 2 + 2 * run] }
		if symbol < 0 || symbol > 3 || size < 1 || size > 8 { return -1 }
		right_total += int(size)
		if right_total > 16 { return -1 }
		right_symbol[run], right_size[run] = symbol, int(size)
	}
	mut bottom := [4][9]i64{}
	mut next_bottom := [4][9]i64{}
	for i in 0 .. left_count {
		mut left_boundary := [9]i64{}
		for j in 0 .. right_count {
			rows, columns := left_size[i], right_size[j]
			mut previous := [9]i64{}
			mut current := [9]i64{}
			mut right_boundary := [9]i64{}
			for column in 0 .. columns + 1 { previous[column] = bottom[j][column] }
			right_boundary[0] = previous[columns]
			for row in 1 .. rows + 1 {
				current[0] = left_boundary[row]
				for column in 1 .. columns + 1 {
					if left_symbol[i] == right_symbol[j] {
						current[column] = previous[column - 1] + 1
					} else if previous[column] > current[column - 1] {
						current[column] = previous[column]
					} else {
						current[column] = current[column - 1]
					}
				}
				right_boundary[row] = current[columns]
				for column in 0 .. columns + 1 { previous[column] = current[column] }
			}
			for column in 0 .. columns + 1 { next_bottom[j][column] = previous[column] }
			for row in 0 .. rows + 1 { left_boundary[row] = right_boundary[row] }
		}
		for j in 0 .. right_count {
			for column in 0 .. right_size[j] + 1 { bottom[j][column] = next_bottom[j][column] }
		}
	}
	return bottom[right_count - 1][right_size[right_count - 1]]
}
