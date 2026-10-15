module word_search

const max_cells = 36
const max_word_length = 15

fn is_letter(value i64) bool {
	return (value >= `A` && value <= `Z`) || (value >= `a` && value <= `z`)
}

fn word_search_visit(input &i64, columns int, rows int, word_start int,
	word_length int, position int, word_index int, mut visited &bool) bool {
	unsafe {
		if visited[position] || input[2 + position] != input[word_start + word_index] { return false }
		visited[position] = true
		if word_index + 1 == word_length {
			visited[position] = false
			return true
		}
		row, column := position / columns, position % columns
		mut found := false
		if row > 0 {
			found = word_search_visit(input, columns, rows, word_start, word_length,
				position - columns, word_index + 1, mut visited)
		}
		if !found && row + 1 < rows {
			found = word_search_visit(input, columns, rows, word_start, word_length,
				position + columns, word_index + 1, mut visited)
		}
		if !found && column > 0 {
			found = word_search_visit(input, columns, rows, word_start, word_length,
				position - 1, word_index + 1, mut visited)
		}
		if !found && column + 1 < columns {
			found = word_search_visit(input, columns, rows, word_start, word_length,
				position + 1, word_index + 1, mut visited)
		}
		visited[position] = false
		return found
	}
}

@[export: 'word_search']
pub fn word_search(input &i64, length usize) i64 {
	if length < 5 { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > 6 || input[1] < 1 || input[1] > 6 { return -1 }
		rows, columns := int(input[0]), int(input[1])
		cells := rows * columns
		word_length_index := 2 + cells
		if int(length) <= word_length_index { return -1 }
		word_length_value := input[word_length_index]
		if word_length_value < 1 || word_length_value > max_word_length ||
			int(length) != word_length_index + 1 + int(word_length_value) { return -1 }
		word_length := int(word_length_value)
		for index in 0 .. cells {
			if !is_letter(input[2 + index]) { return -1 }
		}
		word_start := word_length_index + 1
		for index in 0 .. word_length {
			if !is_letter(input[word_start + index]) { return -1 }
		}
		if word_length > cells { return 0 }
		mut visited := [max_cells]bool{}
		for position in 0 .. cells {
			if word_search_visit(input, columns, rows, word_start, word_length,
				position, 0, mut visited[0]) { return 1 }
		}
		return 0
	}
}
