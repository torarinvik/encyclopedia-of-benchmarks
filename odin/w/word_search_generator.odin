package word_search_generator

import "core:c"

MAX_DIMENSION :: 32
MAX_CELLS :: MAX_DIMENSION * MAX_DIMENSION
MAX_WORDS :: 96
MAX_WORD_LENGTH :: 32
MAX_INPUT_VALUES :: 4096
RNG_MODULUS :: u64(2147483647)

next_random :: proc "contextless" (state: ^u64) -> u64 {
	state^ = (state^ * 48271) % RNG_MODULUS
	return state^
}

is_ascii_letter :: proc "contextless" (value: i64) -> bool {
	return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z')
}

@(export)
word_search_generator :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 4 || length > MAX_INPUT_VALUES do return -1
	width_value := values[0]
	height_value := values[1]
	seed_value := values[2]
	word_count_value := values[3]
	if width_value < 1 || width_value > MAX_DIMENSION ||
		height_value < 1 || height_value > MAX_DIMENSION ||
		seed_value < 1 || seed_value >= i64(RNG_MODULUS) ||
		word_count_value < 0 || word_count_value > MAX_WORDS {
		return -1
	}
	width := int(width_value)
	height := int(height_value)
	word_count := int(word_count_value)

	position := 4
	for _ in 0..<word_count {
		if position >= int(length) do return -1
		word_length_value := values[position]
		position += 1
		if word_length_value < 1 || word_length_value > MAX_WORD_LENGTH ||
			word_length_value > i64(int(length)-position) {
			return -1
		}
		word_length := int(word_length_value)
		for offset in 0..<word_length {
			if !is_ascii_letter(values[position+offset]) do return -1
		}
		position += word_length
	}
	if position != int(length) do return -1

	cells := width * height
	if output == nil || output_capacity < c.size_t(cells) do return -2
	board: [MAX_CELLS]u8 = {}
	rows: [MAX_DIMENSION]int = {}
	columns: [MAX_DIMENSION]int = {}
	row_delta: [8]int = {-1, -1, 0, 1, 1, 1, 0, -1}
	column_delta: [8]int = {0, 1, 1, 1, 0, -1, -1, -1}
	state := u64(seed_value)
	position = 4

	for _ in 0..<word_count {
		word_length := int(values[position])
		position += 1
		word_start := position
		position += word_length
		for row in 0..<height do rows[row] = row
		for column in 0..<width do columns[column] = column

		remaining := height
		for remaining > 1 {
			other := int(next_random(&state) % u64(remaining))
			temporary := rows[remaining-1]
			rows[remaining-1] = rows[other]
			rows[other] = temporary
			remaining -= 1
		}
		remaining = width
		for remaining > 1 {
			other := int(next_random(&state) % u64(remaining))
			temporary := columns[remaining-1]
			columns[remaining-1] = columns[other]
			columns[other] = temporary
			remaining -= 1
		}
		direction := int(next_random(&state) % 8)
		placed := false

		for row_index in 0..<height {
			if placed do break
			for column_index in 0..<width {
				row := rows[row_index]
				column := columns[column_index]
				last_row := row + (word_length-1)*row_delta[direction]
				last_column := column + (word_length-1)*column_delta[direction]
				if last_row < 0 || last_row >= height || last_column < 0 || last_column >= width do continue
				available := true
				for offset in 0..<word_length {
					current_row := row + offset*row_delta[direction]
					current_column := column + offset*column_delta[direction]
					if board[current_row*width+current_column] != 0 {
						available = false
						break
					}
				}
				if !available do continue
				for offset in 0..<word_length {
					current_row := row + offset*row_delta[direction]
					current_column := column + offset*column_delta[direction]
					board[current_row*width+current_column] = u8(values[word_start+offset])
				}
				placed = true
				break
			}
		}
	}
	for index in 0..<cells do output[index] = board[index]
	return i64(cells)
}
