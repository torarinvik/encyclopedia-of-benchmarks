module lgv_nonintersecting_paths

import 'core:c'

const max_height = 5
const max_width = 5
const max_paths = 3
const max_input_length = 11

fn single_source_paths(height int, width int, blocked i64, source_row int, sink_row int) i64 {
	mut ways := [max_height][max_width]i64{}
	for row in 0 .. height {
		for column in 0 .. width {
			bit := row * width + column
			if ((blocked >> bit) & 1) != 0 {
				ways[row][column] = 0
			} else if row == source_row && column == 0 {
				ways[row][column] = 1
			} else {
				if row > 0 { ways[row][column] += ways[row - 1][column] }
				if column > 0 { ways[row][column] += ways[row][column - 1] }
			}
		}
	}
	return ways[sink_row][width - 1]
}

fn determinant(matrix [max_paths][max_paths]i64, order int) i64 {
	second_limit := if order >= 2 { order } else { 1 }
	third_limit := if order >= 3 { order } else { 1 }
	mut total := i64(0)
	for first in 0 .. order {
		for second in 0 .. second_limit {
			if order >= 2 && second == first { continue }
			for third in 0 .. third_limit {
				if order >= 3 && (third == first || third == second) { continue }
				permutation := [3]int{first, second, third}
				mut inversions := 0
				mut product := i64(1)
				for row in 0 .. order {
					product *= matrix[row][permutation[row]]
					for later in row + 1 .. order {
						if permutation[row] > permutation[later] { inversions++ }
					}
				}
				if inversions % 2 == 0 { total += product } else { total -= product }
			}
		}
	}
	return total
}

@[export: 'lgv_nonintersecting_paths']
pub fn lgv_nonintersecting_paths(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_input_length { return -1 }
		height64, width64, path_count64, blocked := input[0], input[1], input[2], input[3]
		if height64 < 1 || height64 > max_height || width64 < 2 || width64 > max_width ||
			path_count64 < 1 || path_count64 > max_paths || blocked < 0 { return -1 }
		height, width, path_count := int(height64), int(width64), int(path_count64)
		if int(length) != 4 + 2 * path_count { return -1 }
		cell_count := height * width
		if blocked >= (i64(1) << cell_count) { return -1 }
		mut sources := [max_paths]int{}
		mut sinks := [max_paths]int{}
		for i in 0 .. path_count {
			source, sink := input[4 + i], input[4 + path_count + i]
			if source < 0 || source >= height64 || sink < 0 || sink >= height64 || source > sink { return -1 }
			if i > 0 && (source <= i64(sources[i - 1]) || sink <= i64(sinks[i - 1])) { return -1 }
			sources[i], sinks[i] = int(source), int(sink)
			if ((blocked >> (sources[i] * width)) & 1) != 0 ||
				((blocked >> (sinks[i] * width + width - 1)) & 1) != 0 { return -1 }
		}
		mut matrix := [max_paths][max_paths]i64{}
		for source_index in 0 .. path_count {
			for sink_index in 0 .. path_count {
				matrix[source_index][sink_index] = single_source_paths(height, width, blocked,
					sources[source_index], sinks[sink_index])
			}
		}
		return determinant(matrix, path_count)
	}
}
