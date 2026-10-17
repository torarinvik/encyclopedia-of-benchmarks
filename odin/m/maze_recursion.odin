package maze_recursion

import "core:c"

GRID_ROWS :: 8
GRID_COLS :: 7
GRID_CELLS :: 56
INPUT_WORDS :: 57
OUTPUT_BYTES :: 228
START_INDEX :: 8
TARGET_INDEX :: 47

solve_maze :: proc "contextless" (grid: [^]u8, row, col, strategy: int) -> bool {
	if grid[TARGET_INDEX] == 2 do return true
	index := row*GRID_COLS + col
	if grid[index] != 0 do return false
	grid[index] = 2
	if strategy == 0 {
		if solve_maze(grid, row+1, col, strategy) do return true
		if solve_maze(grid, row, col+1, strategy) do return true
		if solve_maze(grid, row-1, col, strategy) do return true
		if solve_maze(grid, row, col-1, strategy) do return true
	} else {
		if solve_maze(grid, row-1, col, strategy) do return true
		if solve_maze(grid, row, col+1, strategy) do return true
		if solve_maze(grid, row+1, col, strategy) do return true
		if solve_maze(grid, row, col-1, strategy) do return true
	}
	grid[index] = 3
	return false
}

put_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i32) {
	bits := u32(value)
	for byte := 0; byte < 4; byte += 1 {
		output[offset+byte] = u8(bits >> u32(8*byte))
	}
}

@(export)
maze_recursion :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != c.size_t(INPUT_WORDS) do return -1
	if input[0] < 0 || input[0] > 1 do return -1
	strategy := int(input[0])

	grid: [GRID_CELLS]u8
	for index := 0; index < GRID_CELLS; index += 1 {
		cell := input[index+1]
		if cell != 0 && cell != 1 do return -1
		grid[index] = u8(cell)
	}
	for row := 0; row < GRID_ROWS; row += 1 {
		for col := 0; col < GRID_COLS; col += 1 {
			if (row == 0 || row == GRID_ROWS-1 || col == 0 || col == GRID_COLS-1) &&
				grid[row*GRID_COLS+col] != 1 do return -1
		}
	}
	if grid[START_INDEX] != 0 || grid[TARGET_INDEX] != 0 do return -1
	if output == nil || capacity < c.size_t(OUTPUT_BYTES) do return -2

	found := solve_maze(&grid[0], 1, 1, strategy)
	buffer: [OUTPUT_BYTES]u8
	put_i32_le(&buffer[0], 0, i32(0))
	if found do put_i32_le(&buffer[0], 0, 1)
	for index := 0; index < GRID_CELLS; index += 1 {
		put_i32_le(&buffer[0], 4*(index+1), i32(grid[index]))
	}
	for index := 0; index < OUTPUT_BYTES; index += 1 do output[index] = buffer[index]
	return i64(OUTPUT_BYTES)
}
