package rat_in_amaze

import "core:c"

MAX_DIMENSION :: 4
MAX_CELLS :: MAX_DIMENSION * MAX_DIMENSION
MAX_PATHS :: 184
MAX_PATH_LENGTH :: MAX_CELLS - 1
MAX_PARSEABLE_INPUT_LENGTH :: 19
MAX_OUTPUT_WORDS :: 2097
MAX_OUTPUT_BYTES :: MAX_OUTPUT_WORDS * 8

Maze :: struct {
	variant: int,
	size: int,
	cells: [MAX_CELLS]i64,
}

Paths :: struct {
	directions: [MAX_PATHS][MAX_PATH_LENGTH]u8,
	lengths: [MAX_PATHS]int,
	count: int,
}

rat_in_amaze_collect :: proc(maze: ^Maze, row, col: int, visited: [^]u8,
	current: [^]u8, path_length: int, paths: ^Paths) -> bool {
	if row == maze.size - 1 && col == maze.size - 1 {
		slot := paths.count
		paths.count += 1
		paths.lengths[slot] = path_length
		for index := 0; index < path_length; index += 1 {
			paths.directions[slot][index] = current[index]
		}
		return maze.variant == 1
	}

	index := row * maze.size + col
	visited[index] = 1
	for movement := 0; movement < 4; movement += 1 {
		delta_row := 0
		delta_col := 0
		code := u8(0)
		if maze.variant == 0 {
			if movement == 0 { delta_row, delta_col, code = 1, 0, 0 }
			else if movement == 1 { delta_row, delta_col, code = 0, -1, 1 }
			else if movement == 2 { delta_row, delta_col, code = 0, 1, 2 }
			else { delta_row, delta_col, code = -1, 0, 3 }
		} else {
			if movement == 0 { delta_row, delta_col, code = 0, 1, 2 }
			else if movement == 1 { delta_row, delta_col, code = 1, 0, 0 }
			else if movement == 2 { delta_row, delta_col, code = -1, 0, 3 }
			else { delta_row, delta_col, code = 0, -1, 1 }
		}
		next_row, next_col := row + delta_row, col + delta_col
		if next_row < 0 || next_col < 0 || next_row >= maze.size || next_col >= maze.size do continue
		next_index := next_row * maze.size + next_col
		if maze.cells[next_index] != 1 || visited[next_index] != 0 do continue
		current[path_length] = code
		if rat_in_amaze_collect(maze, next_row, next_col, visited, current, path_length + 1, paths) {
			visited[index] = 0
			return true
		}
	}
	visited[index] = 0
	return false
}

rat_in_amaze_parse :: proc(input: [^]i64, length: int, maze: ^Maze) -> bool {
	if input == nil || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH do return false
	if length < 2 || (input[0] != 0 && input[0] != 1) do return false
	if input[1] < 1 || input[1] > MAX_DIMENSION do return false
	size := int(input[1])
	if length != 2 + size * size do return false
	maze.variant = int(input[0])
	maze.size = size
	for index := 0; index < size * size; index += 1 {
		cell := input[2 + index]
		if cell != 0 && cell != 1 do return false
		maze.cells[index] = cell
	}
	return true
}

rat_in_amaze_write_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
rat_in_amaze :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 1 || input_length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) do return -1
	maze: Maze
	if !rat_in_amaze_parse(input, int(input_length), &maze) do return -1
	paths: Paths
	if maze.cells[0] == 1 && maze.cells[maze.size * maze.size - 1] == 1 {
		visited: [MAX_CELLS]u8 = {}
		current: [MAX_PATH_LENGTH]u8 = {}
		_ = rat_in_amaze_collect(&maze, 0, 0, &visited[0], &current[0], 0, &paths)
	}
	if paths.count == 0 do return -3

	output_words := 1
	for path := 0; path < paths.count; path += 1 {
		output_words += 1 + paths.lengths[path]
	}
	output_bytes := output_words * 8
	if output_bytes > MAX_OUTPUT_BYTES do return -1
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2

	offset := 0
	rat_in_amaze_write_i64_le(output, offset, i64(paths.count))
	offset += 8
	for path := 0; path < paths.count; path += 1 {
		rat_in_amaze_write_i64_le(output, offset, i64(paths.lengths[path]))
		offset += 8
		for movement := 0; movement < paths.lengths[path]; movement += 1 {
			rat_in_amaze_write_i64_le(output, offset, i64(paths.directions[path][movement]))
			offset += 8
		}
	}
	return i64(output_bytes)
}
