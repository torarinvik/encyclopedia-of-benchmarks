module rat_maze

const max_n = 8
const max_input_words = 1 + max_n * max_n
const max_output_bytes = 4 * (1 + max_n * max_n)

fn search_path(input &i32, mut path &i32, n int, row int, col int) bool {
	index := row * n + col
	unsafe { path[index] = 1 }
	if row == n - 1 && col == n - 1 { return true }
	unsafe {
		if col + 1 < n && input[1 + index + 1] == 1 && search_path(input, mut path, n, row, col + 1) { return true }
		if row + 1 < n && input[1 + index + n] == 1 && search_path(input, mut path, n, row + 1, col) { return true }
		path[index] = 0
	}
	return false
}

fn put_i32_le(mut output &u8, offset int, value i32) {
	mut bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'rat_maze']
pub fn rat_maze(input &i32, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > usize(max_input_words) { return -1 }
		n_raw := input[0]
		if n_raw < 1 || n_raw > max_n { return -1 }
		n := int(n_raw)
		cells := n * n
		if int(length) != 1 + cells || input[1] != 1 { return -1 }
		for i in 0 .. cells { if input[1 + i] < 0 || input[1 + i] > 1 { return -1 } }
		mut path := [max_n * max_n]i32{}
		found := search_path(input, mut path[0], n, 0, 0)
		word_count := if found { 1 + cells } else { 1 }
		bytes := word_count * 4
		if output == nil || capacity < usize(bytes) { return -2 }
		mut buffer := [max_output_bytes]u8{}
		put_i32_le(mut buffer[0], 0, if found { 1 } else { 0 })
		if found {
			for i in 0 .. cells { put_i32_le(mut buffer[0], (i + 1) * 4, path[i]) }
		}
		for i in 0 .. bytes { output[i] = buffer[i] }
		return i64(bytes)
	}
}
