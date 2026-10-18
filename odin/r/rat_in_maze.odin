package rat_in_maze

import "core:c"

MAX_DIMENSION :: 8
MAX_CELLS :: MAX_DIMENSION * MAX_DIMENSION
MAX_PARSEABLE_INPUT_LENGTH :: 71
MAX_OUTPUT_BYTES :: MAX_CELLS * 8

Maze :: struct {
	variant: int,
	rows: int,
	cols: int,
	start_row: int,
	start_col: int,
	destination_row: int,
	destination_col: int,
	cells: [MAX_CELLS]i64,
}

rat_in_maze_search :: proc(maze: ^Maze, row, col: int, path: [^]u8) -> bool {
	if maze.variant == 1 && row == maze.destination_row && col == maze.destination_col {
		path[row * maze.cols + col] = 1
		return true
	}
	if row < 0 || col < 0 || row >= maze.rows || col >= maze.cols do return false
	index := row * maze.cols + col
	open_value := i64(1)
	if maze.variant == 0 do open_value = 0
	if maze.cells[index] != open_value || path[index] != 0 do return false
	path[index] = 1
	if maze.variant == 0 && row == maze.destination_row && col == maze.destination_col do return true

	for movement := 0; movement < 4; movement += 1 {
		delta_row := 0
		delta_col := 0
		if maze.variant == 0 {
			if movement == 0 { delta_row, delta_col = 1, 0 }
			else if movement == 1 { delta_row, delta_col = 0, 1 }
			else if movement == 2 { delta_row, delta_col = -1, 0 }
			else { delta_row, delta_col = 0, -1 }
		} else {
			if movement == 0 { delta_row, delta_col = 0, 1 }
			else if movement == 1 { delta_row, delta_col = 1, 0 }
			else if movement == 2 { delta_row, delta_col = 0, -1 }
			else { delta_row, delta_col = -1, 0 }
		}
		if rat_in_maze_search(maze, row + delta_row, col + delta_col, path) do return true
	}
	path[index] = 0
	return false
}

rat_in_maze_parse :: proc(input: [^]i64, length: int, maze: ^Maze) -> bool {
	if input == nil || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH do return false
	if input[0] == 0 {
		if length < 7 || input[1] < 1 || input[1] > MAX_DIMENSION do return false
		size := int(input[1])
		if length != 6 + size * size do return false
		if input[2] < 0 || input[2] >= i64(size) || input[3] < 0 || input[3] >= i64(size) ||
			input[4] < 0 || input[4] >= i64(size) || input[5] < 0 || input[5] >= i64(size) do return false
		maze.variant = 0
		maze.rows = size
		maze.cols = size
		maze.start_row = int(input[2])
		maze.start_col = int(input[3])
		maze.destination_row = int(input[4])
		maze.destination_col = int(input[5])
		for index := 0; index < size * size; index += 1 {
			cell := input[6 + index]
			if cell != 0 && cell != 1 do return false
			maze.cells[index] = cell
		}
	} else if input[0] == 1 {
		if length < 6 || input[1] < 1 || input[1] > MAX_DIMENSION || input[2] < 1 || input[2] > MAX_DIMENSION do return false
		rows, cols := int(input[1]), int(input[2])
		if length != 5 + rows * cols || input[3] < 0 || input[3] >= i64(rows) ||
			input[4] < 0 || input[4] >= i64(cols) do return false
		maze.variant = 1
		maze.rows = rows
		maze.cols = cols
		maze.start_row = int(input[3])
		maze.start_col = int(input[4])
		maze.destination_row = rows - 1
		maze.destination_col = cols - 1
		for index := 0; index < rows * cols; index += 1 {
			cell := input[5 + index]
			if cell != 0 && cell != 1 do return false
			maze.cells[index] = cell
		}
	} else { return false }
	return true
}

rat_in_maze_write_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
rat_in_maze :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 1 || input_length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) do return -1
	maze: Maze
	if !rat_in_maze_parse(input, int(input_length), &maze) do return -1
	path: [MAX_CELLS]u8 = {}
	if !rat_in_maze_search(&maze, maze.start_row, maze.start_col, &path[0]) do return -3
	cells := maze.rows * maze.cols
	output_bytes := cells * 8
	if output_bytes > MAX_OUTPUT_BYTES do return -1
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2
	for index := 0; index < cells; index += 1 {
		value := i64(0)
		if maze.variant == 0 {
			if path[index] == 0 do value = 1
		} else if path[index] != 0 do value = 1
		rat_in_maze_write_i64_le(output, index * 8, value)
	}
	return i64(output_bytes)
}
