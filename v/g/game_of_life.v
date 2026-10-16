module game_of_life

const max_side = 32

@[export: 'game_of_life']
pub fn game_of_life(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length == 0 { return -1 }
	unsafe {
		side_value := input[0]
		if side_value < 0 || side_value > max_side { return -1 }
		side := int(side_value)
		cell_count := side * side
		if length != usize(cell_count + 1) { return -1 }
		for index in 0 .. cell_count {
			if input[index + 1] != 0 && input[index + 1] != 1 { return -1 }
		}
		if output_capacity < usize(cell_count) || (cell_count > 0 && output == nil) { return -2 }
		for row in 0 .. side {
			for column in 0 .. side {
				mut neighbors := 0
				for row_delta in -1 .. 2 {
					for column_delta in -1 .. 2 {
						if row_delta == 0 && column_delta == 0 { continue }
						neighbor_row := row + row_delta
						neighbor_column := column + column_delta
						if neighbor_row >= 0 && neighbor_row < side &&
							neighbor_column >= 0 && neighbor_column < side &&
							input[1 + neighbor_row * side + neighbor_column] == 1 {
							neighbors++
						}
					}
				}
				index := row * side + column
				alive := input[index + 1] == 1
				output[index] = u8((alive && (neighbors == 2 || neighbors == 3)) ||
					(!alive && neighbors == 3))
			}
		}
		return i64(cell_count)
	}
}
