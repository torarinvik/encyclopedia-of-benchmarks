package word_search

import "core:c"

MAX_CELLS :: 36
MAX_WORD_LENGTH :: 15

is_letter :: proc "contextless" (value: i64) -> bool {
	return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z')
}

word_search_visit :: proc "contextless" (input: [^]i64, columns, rows: int,
		word_start, word_length, position, word_index: int, visited: [^]bool) -> bool {
	if visited[position] || input[2 + position] != input[word_start + word_index] do return false
	visited[position] = true
	if word_index + 1 == word_length {
		visited[position] = false
		return true
	}
	row, column := position / columns, position % columns
	found := false
	if row > 0 {
		found = word_search_visit(input, columns, rows, word_start, word_length,
			position - columns, word_index + 1, visited)
	}
	if !found && row + 1 < rows {
		found = word_search_visit(input, columns, rows, word_start, word_length,
			position + columns, word_index + 1, visited)
	}
	if !found && column > 0 {
		found = word_search_visit(input, columns, rows, word_start, word_length,
			position - 1, word_index + 1, visited)
	}
	if !found && column + 1 < columns {
		found = word_search_visit(input, columns, rows, word_start, word_length,
			position + 1, word_index + 1, visited)
	}
	visited[position] = false
	return found
}

@(export)
word_search :: proc "contextless" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 5 || input[0] < 1 || input[0] > 6 || input[1] < 1 || input[1] > 6 {
		return -1
	}
	rows, columns := int(input[0]), int(input[1])
	cells := rows * columns
	word_length_index := 2 + cells
	if int(length) <= word_length_index do return -1
	word_length_value := input[word_length_index]
	if word_length_value < 1 || word_length_value > MAX_WORD_LENGTH ||
		int(length) != word_length_index + 1 + int(word_length_value) { return -1 }
	word_length := int(word_length_value)
	for index := 0; index < cells; index += 1 {
		if !is_letter(input[2 + index]) do return -1
	}
	word_start := word_length_index + 1
	for index := 0; index < word_length; index += 1 {
		if !is_letter(input[word_start + index]) do return -1
	}
	if word_length > cells do return 0
	visited: [MAX_CELLS]bool = {}
	for position := 0; position < cells; position += 1 {
		if word_search_visit(input, columns, rows, word_start, word_length,
			position, 0, &visited[0]) { return 1 }
	}
	return 0
}
