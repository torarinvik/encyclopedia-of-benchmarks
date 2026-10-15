module word_search_generator

const max_dimension = 32
const max_cells = max_dimension * max_dimension
const max_words = 96
const max_word_length = 32
const max_input_values = 4096
const rng_modulus = u64(2147483647)

fn next_random(mut state &u64) u64 {
	unsafe {
		state[0] = (state[0] * u64(48271)) % rng_modulus
		return state[0]
	}
}

fn is_ascii_letter(value i64) bool {
	return (value >= 65 && value <= 90) || (value >= 97 && value <= 122)
}

@[export: 'word_search_generator']
pub fn word_search_generator(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { values == nil } || length < 4 || length > max_input_values { return -1 }
	width_value := unsafe { values[0] }
	height_value := unsafe { values[1] }
	seed_value := unsafe { values[2] }
	word_count_value := unsafe { values[3] }
	if width_value < 1 || width_value > i64(max_dimension) ||
		height_value < 1 || height_value > i64(max_dimension) ||
		seed_value < 1 || seed_value >= i64(rng_modulus) ||
		word_count_value < 0 || word_count_value > i64(max_words) { return -1 }
	width := int(width_value)
	height := int(height_value)
	word_count := int(word_count_value)

	mut position := 4
	for _ in 0 .. word_count {
		if position >= int(length) { return -1 }
		word_length_value := unsafe { values[position] }
		position++
		if word_length_value < 1 || word_length_value > i64(max_word_length) ||
			word_length_value > i64(int(length)-position) { return -1 }
		word_length := int(word_length_value)
		for offset in 0 .. word_length {
			if !is_ascii_letter(unsafe { values[position+offset] }) { return -1 }
		}
		position += word_length
	}
	if position != int(length) { return -1 }

	cells := width * height
	if unsafe { output == nil } || output_capacity < usize(cells) { return -2 }
	mut board := [max_cells]u8{}
	mut rows := [max_dimension]usize{}
	mut columns := [max_dimension]usize{}
	row_delta := [-1, -1, 0, 1, 1, 1, 0, -1]
	column_delta := [0, 1, 1, 1, 0, -1, -1, -1]
	mut state := u64(seed_value)
	position = 4

	for _ in 0 .. word_count {
		word_length := int(unsafe { values[position] })
		position++
		word_start := position
		position += word_length
		for row in 0 .. height { rows[row] = usize(row) }
		for column in 0 .. width { columns[column] = usize(column) }

		mut remaining := height
		for remaining > 1 {
			other := int(next_random(mut state) % u64(remaining))
			temporary := rows[remaining-1]
			rows[remaining-1] = rows[other]
			rows[other] = temporary
			remaining--
		}
		remaining = width
		for remaining > 1 {
			other := int(next_random(mut state) % u64(remaining))
			temporary := columns[remaining-1]
			columns[remaining-1] = columns[other]
			columns[other] = temporary
			remaining--
		}
		direction := int(next_random(mut state) % u64(8))
		mut placed := false

		for row_index in 0 .. height {
			if placed { break }
			for column_index in 0 .. width {
				row := int(rows[row_index])
				column := int(columns[column_index])
				last_row := row + (word_length-1) * row_delta[direction]
				last_column := column + (word_length-1) * column_delta[direction]
				if last_row < 0 || last_row >= height || last_column < 0 || last_column >= width { continue }
				mut available := true
				for offset in 0 .. word_length {
					current_row := row + offset * row_delta[direction]
					current_column := column + offset * column_delta[direction]
					if board[current_row*width+current_column] != 0 {
						available = false
						break
					}
				}
				if !available { continue }
				for offset in 0 .. word_length {
					current_row := row + offset * row_delta[direction]
					current_column := column + offset * column_delta[direction]
					unsafe { board[current_row*width+current_column] = u8(values[word_start+offset]) }
				}
				placed = true
				break
			}
		}
	}
	for index in 0 .. cells { unsafe { output[index] = board[index] } }
	return i64(cells)
}
