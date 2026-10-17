module rotting_oranges

const max_cells = 256
const max_input_length = 259
const invalid_result = i64(-9223372036854775808)

@[export: 'rotting_oranges']
pub fn rotting_oranges(input &i64, length usize) i64 {
	if unsafe { input == nil } {
		if length == 0 { return 0 }
		return invalid_result
	}
	if length == 0 { return 0 }
	if length < 2 || length > max_input_length { return invalid_result }
	unsafe {
		if input[0] == 0 {
			if input[1] == 0 && length == 2 { return 0 }
			return invalid_result
		}
		if input[0] < 1 || input[0] > 16 || input[1] < 0 || input[1] > 16 {
			return invalid_result
		}
		rows, columns := int(input[0]), int(input[1])
		cell_count := rows * columns
		if length != usize(2 + cell_count) { return invalid_result }

		mut cells := [max_cells]u8{}
		mut queue := [max_cells]int{}
		mut distance := [max_cells]int{}
		mut head, mut tail, mut fresh, mut rotted := 0, 0, 0, 0
		for index in 0 .. cell_count {
			value := input[2 + index]
			if value < 0 || value > 2 { return invalid_result }
			cells[index] = u8(value)
			if value == 1 { fresh++ }
			if value == 2 {
				queue[tail] = index
				tail++
			}
		}
		if columns == 0 || fresh == 0 { return 0 }

		mut minutes := 0
		for head < tail {
			index := queue[head]
			head++
			row, column := index / columns, index % columns
			next_distance := distance[index] + 1
			if row > 0 {
				next := index - columns
				if cells[next] == 1 {
					cells[next] = 2
					distance[next] = next_distance
					if next_distance > minutes { minutes = next_distance }
					rotted++
					queue[tail] = next
					tail++
				}
			}
			if column + 1 < columns {
				next := index + 1
				if cells[next] == 1 {
					cells[next] = 2
					distance[next] = next_distance
					if next_distance > minutes { minutes = next_distance }
					rotted++
					queue[tail] = next
					tail++
				}
			}
			if row + 1 < rows {
				next := index + columns
				if cells[next] == 1 {
					cells[next] = 2
					distance[next] = next_distance
					if next_distance > minutes { minutes = next_distance }
					rotted++
					queue[tail] = next
					tail++
				}
			}
			if column > 0 {
				next := index - 1
				if cells[next] == 1 {
					cells[next] = 2
					distance[next] = next_distance
					if next_distance > minutes { minutes = next_distance }
					rotted++
					queue[tail] = next
					tail++
				}
			}
		}
		if rotted == fresh { return i64(minutes) }
		return -1
	}
}
