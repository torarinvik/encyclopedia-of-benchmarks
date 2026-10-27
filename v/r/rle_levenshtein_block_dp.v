module rle_levenshtein_block_dp

// Run-length-native unit-cost edit distance by run-pair blocks.
@[export: 'rle_levenshtein_block_dp']
pub fn rle_levenshtein_block_dp(packed &i64, length usize) i64 {
	if packed == unsafe { nil } || length < 4 || length > 18 { return -1 }
	left_count_raw := unsafe { packed[0] }
	if left_count_raw < 1 || left_count_raw > 4 { return -1 }
	left_count := int(left_count_raw)
	right_index := 1 + 2 * left_count
	if right_index >= int(length) { return -1 }
	right_count_raw := unsafe { packed[right_index] }
	if right_count_raw < 1 || right_count_raw > 4 || int(length) != right_index + 1 + 2 * int(right_count_raw) { return -1 }
	right_count := int(right_count_raw)
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
		left_total += int(size); if left_total > 16 { return -1 }
		left_symbol[run], left_size[run] = symbol, int(size)
	}
	for run in 0 .. right_count {
		symbol := unsafe { packed[right_index + 1 + 2 * run] }
		size := unsafe { packed[right_index + 2 + 2 * run] }
		if symbol < 0 || symbol > 3 || size < 1 || size > 8 { return -1 }
		right_total += int(size); if right_total > 16 { return -1 }
		right_symbol[run], right_size[run] = symbol, int(size)
	}
	mut bottom := [4][9]i64{}
	mut next_bottom := [4][9]i64{}
	mut right_prefix := 0
	for j in 0 .. right_count {
		for column in 0 .. right_size[j] + 1 { bottom[j][column] = i64(right_prefix + column) }
		right_prefix += right_size[j]
	}
	mut left_prefix := 0
	for i in 0 .. left_count {
		rows := left_size[i]
		mut left_boundary := [9]i64{}
		for row in 0 .. rows + 1 { left_boundary[row] = i64(left_prefix + row) }
		for j in 0 .. right_count {
			columns := right_size[j]
			mut previous := [9]i64{}
			mut current := [9]i64{}
			mut right_boundary := [9]i64{}
			for column in 0 .. columns + 1 { previous[column] = bottom[j][column] }
			right_boundary[0] = previous[columns]
			mut substitution := i64(0)
			if left_symbol[i] != right_symbol[j] { substitution = 1 }
			for row in 1 .. rows + 1 {
				current[0] = left_boundary[row]
				for column in 1 .. columns + 1 {
					deletion := previous[column] + 1
					insertion := current[column - 1] + 1
					replace := previous[column - 1] + substitution
					mut best := deletion
					if insertion < best { best = insertion }
					if replace < best { best = replace }
					current[column] = best
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
		left_prefix += rows
	}
	return bottom[right_count - 1][right_size[right_count - 1]]
}
