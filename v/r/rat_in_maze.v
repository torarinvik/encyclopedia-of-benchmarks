const max_dimension = 8
const max_cells = max_dimension * max_dimension
const max_parseable_input_length = 71
const max_output_bytes = max_cells * 8

struct Maze {
	variant int
	rows int
	cols int
	start_row int
	start_col int
	destination_row int
	destination_col int
	cells [max_cells]i64
}

fn rat_in_maze_direction(variant int, movement int) (int, int) {
	if variant == 0 {
		match movement {
			0 { return 1, 0 }
			1 { return 0, 1 }
			2 { return -1, 0 }
			else { return 0, -1 }
		}
	}
	match movement {
		0 { return 0, 1 }
		1 { return 1, 0 }
		2 { return 0, -1 }
		else { return -1, 0 }
	}
}

fn rat_in_maze_search(maze &Maze, row int, col int, mut path &u8) bool {
	if maze.variant == 1 && row == maze.destination_row && col == maze.destination_col {
		unsafe { path[row * maze.cols + col] = 1 }
		return true
	}
	if row < 0 || col < 0 || row >= maze.rows || col >= maze.cols { return false }
	index := row * maze.cols + col
	open_value := if maze.variant == 0 { i64(0) } else { i64(1) }
	unsafe {
		if maze.cells[index] != open_value || path[index] != 0 { return false }
		path[index] = 1
	}
	if maze.variant == 0 && row == maze.destination_row && col == maze.destination_col { return true }
	for movement in 0 .. 4 {
		delta_row, delta_col := rat_in_maze_direction(maze.variant, movement)
		if rat_in_maze_search(maze, row + delta_row, col + delta_col, mut path) { return true }
	}
	unsafe { path[index] = 0 }
	false
}

fn rat_in_maze_parse(values &i64, length usize, mut maze &Maze) bool {
	unsafe {
		if values == nil || length < 1 || length > max_parseable_input_length { return false }
		if values[0] == 0 {
			if length < 7 || values[1] < 1 || values[1] > max_dimension { return false }
			size := int(values[1])
			if length != usize(6 + size * size) { return false }
			if values[2] < 0 || values[2] >= size || values[3] < 0 || values[3] >= size ||
				values[4] < 0 || values[4] >= size || values[5] < 0 || values[5] >= size { return false }
			maze.variant = 0
			maze.rows = size
			maze.cols = size
			maze.start_row = int(values[2])
			maze.start_col = int(values[3])
			maze.destination_row = int(values[4])
			maze.destination_col = int(values[5])
			for index in 0 .. size * size {
				cell := values[6 + index]
				if cell != 0 && cell != 1 { return false }
				maze.cells[index] = cell
			}
		} else if values[0] == 1 {
			if length < 6 || values[1] < 1 || values[1] > max_dimension || values[2] < 1 || values[2] > max_dimension { return false }
			rows, cols := int(values[1]), int(values[2])
			if length != usize(5 + rows * cols) || values[3] < 0 || values[3] >= rows || values[4] < 0 || values[4] >= cols { return false }
			maze.variant = 1
			maze.rows = rows
			maze.cols = cols
			maze.start_row = int(values[3])
			maze.start_col = int(values[4])
			maze.destination_row = rows - 1
			maze.destination_col = cols - 1
			for index in 0 .. rows * cols {
				cell := values[5 + index]
				if cell != 0 && cell != 1 { return false }
				maze.cells[index] = cell
			}
		} else { return false }
	}
	true
}

fn rat_in_maze_write_i64_le(mut output &u8, offset int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'rat_in_maze']
pub fn rat_in_maze(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 1 || input_length > max_parseable_input_length { return -1 }
		mut maze := Maze{}
		if !rat_in_maze_parse(input, input_length, mut maze) { return -1 }
		mut path := [max_cells]u8{}
		if !rat_in_maze_search(&maze, maze.start_row, maze.start_col, mut path[0]) { return -3 }
		cells := maze.rows * maze.cols
		output_bytes := cells * 8
		if output_bytes > max_output_bytes { return -1 }
		if output == nil || output_capacity < usize(output_bytes) { return -2 }
		for index in 0 .. cells {
			mut value := i64(0)
			if maze.variant == 0 {
				if path[index] == 0 { value = 1 }
			} else if path[index] != 0 { value = 1 }
			rat_in_maze_write_i64_le(mut output, index * 8, value)
		}
		return i64(output_bytes)
	}
}
