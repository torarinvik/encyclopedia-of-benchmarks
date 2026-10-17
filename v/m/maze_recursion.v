module maze_recursion

const grid_rows = 8
const grid_cols = 7
const grid_cells = 56
const input_words = 57
const output_bytes = 228
const start_index = 8
const target_index = 47

fn solve_maze(mut grid []u8, row int, col int, strategy int) bool {
	if grid[target_index] == 2 { return true }
	index := row * grid_cols + col
	if grid[index] != 0 { return false }
	grid[index] = 2
	if strategy == 0 {
		if solve_maze(mut grid, row + 1, col, strategy) { return true }
		if solve_maze(mut grid, row, col + 1, strategy) { return true }
		if solve_maze(mut grid, row - 1, col, strategy) { return true }
		if solve_maze(mut grid, row, col - 1, strategy) { return true }
	} else {
		if solve_maze(mut grid, row - 1, col, strategy) { return true }
		if solve_maze(mut grid, row, col + 1, strategy) { return true }
		if solve_maze(mut grid, row + 1, col, strategy) { return true }
		if solve_maze(mut grid, row, col - 1, strategy) { return true }
	}
	grid[index] = 3
	return false
}

fn put_i32_le(mut output &u8, offset int, value i32) {
	mut bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'maze_recursion']
pub fn maze_recursion(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length != usize(input_words) { return -1 }
		if input[0] < 0 || input[0] > 1 { return -1 }
		strategy := int(input[0])

		mut grid := []u8{len: grid_cells, init: 0}
		for index := 0; index < grid_cells; index++ {
			cell := input[index + 1]
			if cell != 0 && cell != 1 { return -1 }
			grid[index] = u8(cell)
		}
		for row := 0; row < grid_rows; row++ {
			for col := 0; col < grid_cols; col++ {
				if (row == 0 || row == grid_rows - 1 || col == 0 || col == grid_cols - 1) &&
					grid[row * grid_cols + col] != 1 { return -1 }
			}
		}
		if grid[start_index] != 0 || grid[target_index] != 0 { return -1 }
		if output == nil || capacity < usize(output_bytes) { return -2 }

		found := solve_maze(mut grid, 1, 1, strategy)
		mut buffer := [output_bytes]u8{init: 0}
		put_i32_le(mut buffer[0], 0, if found { i32(1) } else { i32(0) })
		for index := 0; index < grid_cells; index++ {
			put_i32_le(mut buffer[0], 4 * (index + 1), i32(grid[index]))
		}
		for index := 0; index < output_bytes; index++ { output[index] = buffer[index] }
		return i64(output_bytes)
	}
}
