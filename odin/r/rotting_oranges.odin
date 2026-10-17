package rotting_oranges

import "core:c"

MAX_CELLS :: 256
MAX_INPUT_LENGTH :: 259
INVALID_RESULT :: i64 = -9223372036854775808

rotting_oranges :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil {
		if length == 0 do return 0
		return INVALID_RESULT
	}
	if length == 0 do return 0
	if length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return INVALID_RESULT
	if input[0] == 0 {
		if input[1] == 0 && length == 2 do return 0
		return INVALID_RESULT
	}
	if input[0] < 1 || input[0] > 16 || input[1] < 0 || input[1] > 16 {
		return INVALID_RESULT
	}

	rows, columns := int(input[0]), int(input[1])
	cell_count := rows * columns
	if int(length) != 2 + cell_count do return INVALID_RESULT

	cells: [MAX_CELLS]u8
	queue: [MAX_CELLS]int
	distance: [MAX_CELLS]int
	head, tail, fresh, rotted := 0, 0, 0, 0
	for index := 0; index < cell_count; index += 1 {
		value := input[2 + index]
		if value < 0 || value > 2 do return INVALID_RESULT
		cells[index] = u8(value)
		if value == 1 {
			fresh += 1
		} else if value == 2 {
			queue[tail] = index
			tail += 1
		}
	}
	if columns == 0 || fresh == 0 do return 0

	minutes := 0
	for head < tail {
		index := queue[head]
		head += 1
		row, column := index / columns, index % columns
		next_distance := distance[index] + 1
		if row > 0 {
			next := index - columns
			if cells[next] == 1 {
				cells[next] = 2
				distance[next] = next_distance
				if next_distance > minutes do minutes = next_distance
				rotted += 1
				queue[tail] = next
				tail += 1
			}
		}
		if column + 1 < columns {
			next := index + 1
			if cells[next] == 1 {
				cells[next] = 2
				distance[next] = next_distance
				if next_distance > minutes do minutes = next_distance
				rotted += 1
				queue[tail] = next
				tail += 1
			}
		}
		if row + 1 < rows {
			next := index + columns
			if cells[next] == 1 {
				cells[next] = 2
				distance[next] = next_distance
				if next_distance > minutes do minutes = next_distance
				rotted += 1
				queue[tail] = next
				tail += 1
			}
		}
		if column > 0 {
			next := index - 1
			if cells[next] == 1 {
				cells[next] = 2
				distance[next] = next_distance
				if next_distance > minutes do minutes = next_distance
				rotted += 1
				queue[tail] = next
				tail += 1
			}
		}
	}
	if rotted == fresh do return i64(minutes)
	return -1
}
