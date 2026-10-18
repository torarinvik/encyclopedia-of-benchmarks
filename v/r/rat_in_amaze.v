const max_dimension = 4
const max_cells = max_dimension * max_dimension
const max_path_length = max_cells - 1
const max_parseable_input_length = 19
const max_output_words = 2097
const max_output_bytes = max_output_words * 8

struct Maze {
	variant int
	size int
	cells [max_cells]i64
}

struct Paths {
	words [max_output_words]i64
	word_count int
	count int
}

fn rat_in_amaze_direction(variant int, movement int) (int, int, u8) {
	if variant == 0 {
		match movement {
			0 { return 1, 0, 0 }
			1 { return 0, -1, 1 }
			2 { return 0, 1, 2 }
			else { return -1, 0, 3 }
		}
	}
	match movement {
		0 { return 0, 1, 2 }
		1 { return 1, 0, 0 }
		2 { return -1, 0, 3 }
		else { return 0, -1, 1 }
	}
}

fn rat_in_amaze_collect(maze &Maze, row int, col int, mut visited &u8,
	mut current &u8, path_length int, mut paths &Paths) bool {
	if row == maze.size - 1 && col == maze.size - 1 {
		paths.words[paths.word_count] = i64(path_length)
		paths.word_count += 1
		for index in 0 .. path_length {
			paths.words[paths.word_count] = i64(current[index])
			paths.word_count += 1
		}
		paths.count += 1
		paths.words[0] = i64(paths.count)
		return maze.variant == 1
	}
	index := row * maze.size + col
	unsafe { visited[index] = 1 }
	for movement in 0 .. 4 {
		delta_row, delta_col, code := rat_in_amaze_direction(maze.variant, movement)
		next_row, next_col := row + delta_row, col + delta_col
		if next_row < 0 || next_col < 0 || next_row >= maze.size || next_col >= maze.size { continue }
		next_index := next_row * maze.size + next_col
		unsafe {
			if maze.cells[next_index] != 1 || visited[next_index] != 0 { continue }
			current[path_length] = code
		}
		if rat_in_amaze_collect(maze, next_row, next_col, mut visited, mut current, path_length + 1, mut paths) {
			unsafe { visited[index] = 0 }
			return true
		}
	}
	unsafe { visited[index] = 0 }
	return false
}

fn rat_in_amaze_parse(values &i64, length int, mut maze &Maze) bool {
	unsafe {
		if values == nil || length < 2 || length > max_parseable_input_length { return false }
		if (values[0] != 0 && values[0] != 1) || values[1] < 1 || values[1] > max_dimension { return false }
		size := int(values[1])
		if length != 2 + size * size { return false }
		maze.variant = int(values[0])
		maze.size = size
		for index := 0; index < size * size; index += 1 {
			cell := values[2 + index]
			if cell != 0 && cell != 1 { return false }
			maze.cells[index] = cell
		}
	}
	return true
}

fn rat_in_amaze_write_i64_le(mut output &u8, offset int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'rat_in_amaze']
pub fn rat_in_amaze(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 1 || input_length > usize(max_parseable_input_length) { return -1 }
		mut maze := Maze{}
		if !rat_in_amaze_parse(input, int(input_length), mut maze) { return -1 }
		mut paths := Paths{}
		paths.word_count = 1
		if maze.cells[0] == 1 && maze.cells[maze.size * maze.size - 1] == 1 {
			mut visited := [max_cells]u8{}
			mut current := [max_path_length]u8{}
			rat_in_amaze_collect(&maze, 0, 0, mut visited[0], mut current[0], 0, mut paths)
		}
		if paths.count == 0 { return -3 }
		output_bytes := paths.word_count * 8
		if output_bytes > max_output_bytes { return -1 }
		if output == nil || output_capacity < usize(output_bytes) { return -2 }
		for index in 0 .. paths.word_count {
			rat_in_amaze_write_i64_le(mut output, index * 8, paths.words[index])
		}
		return i64(output_bytes)
	}
}
