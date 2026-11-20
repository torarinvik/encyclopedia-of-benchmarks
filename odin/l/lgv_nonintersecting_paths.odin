package lgv_nonintersecting_paths

import "core:c"

MAX_HEIGHT :: 5
MAX_WIDTH :: 5
MAX_PATHS :: 3
MAX_INPUT_LENGTH :: 11

single_source_paths :: proc(height, width: int, blocked: i64, source_row, sink_row: int) -> i64 {
	var ways: [MAX_HEIGHT][MAX_WIDTH]i64
	for row := 0; row < height; row += 1 {
		for column := 0; column < width; column += 1 {
			bit := row*width + column
			if ((blocked >> bit) & 1) != 0 {
				ways[row][column] = 0
			} else if row == source_row && column == 0 {
				ways[row][column] = 1
			} else {
				if row > 0 do ways[row][column] += ways[row-1][column]
				if column > 0 do ways[row][column] += ways[row][column-1]
			}
		}
	}
	return ways[sink_row][width-1]
}

determinant :: proc(matrix: [MAX_PATHS][MAX_PATHS]i64, order: int) -> i64 {
	var total: i64 = 0
	second_limit := order
	third_limit := order
	if order < 2 do second_limit = 1
	if order < 3 do third_limit = 1
	for first := 0; first < order; first += 1 {
		for second := 0; second < second_limit; second += 1 {
			if order >= 2 && second == first do continue
			for third := 0; third < third_limit; third += 1 {
				if order >= 3 && (third == first || third == second) do continue
				permutation := [3]int{first, second, third}
				inversions := 0
				product: i64 = 1
				for row := 0; row < order; row += 1 {
					product *= matrix[row][permutation[row]]
					for later := row+1; later < order; later += 1 {
						if permutation[row] > permutation[later] do inversions += 1
					}
				}
				if inversions%2 == 0 { total += product } else { total -= product }
			}
		}
	}
	return total
}

@(export)
lgv_nonintersecting_paths :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT_LENGTH do return -1
	height64, width64, path_count64, blocked := input[0], input[1], input[2], input[3]
	if height64 < 1 || height64 > MAX_HEIGHT || width64 < 2 || width64 > MAX_WIDTH ||
		path_count64 < 1 || path_count64 > MAX_PATHS || blocked < 0 do return -1
	height, width, path_count := int(height64), int(width64), int(path_count64)
	if length != c.size_t(4 + 2*path_count) do return -1
	cell_count := height * width
	if blocked >= (i64(1) << cell_count) do return -1
	var sources, sinks: [MAX_PATHS]int
	for i := 0; i < path_count; i += 1 {
		source, sink := input[4+i], input[4+path_count+i]
		if source < 0 || source >= height64 || sink < 0 || sink >= height64 || source > sink do return -1
		if i > 0 && (source <= i64(sources[i-1]) || sink <= i64(sinks[i-1])) do return -1
		sources[i], sinks[i] = int(source), int(sink)
		if ((blocked >> (sources[i]*width)) & 1) != 0 ||
			((blocked >> (sinks[i]*width+width-1)) & 1) != 0 do return -1
	}
	var matrix: [MAX_PATHS][MAX_PATHS]i64
	for source_index := 0; source_index < path_count; source_index += 1 {
		for sink_index := 0; sink_index < path_count; sink_index += 1 {
			matrix[source_index][sink_index] = single_source_paths(height, width, blocked,
				sources[source_index], sinks[sink_index])
		}
	}
	return determinant(matrix, path_count)
}
