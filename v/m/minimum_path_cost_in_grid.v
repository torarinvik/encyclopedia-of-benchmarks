module minimum_path_cost_in_grid

@[export: 'minimum_path_cost_in_grid']
pub fn minimum_path_cost_in_grid(input &i64, length usize) i64 {
	if length < 2 { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > 32 || input[1] < 1 || input[1] > 32 { return -1 }
		rows := int(input[0])
		columns := int(input[1])
		cells := rows * columns
		move_offset := 2 + cells
		if int(length) != move_offset + cells * columns { return -1 }
		for index in 0 .. cells {
			if input[2 + index] < 0 || input[2 + index] >= i64(cells) { return -1 }
		}
		for index in 0 .. cells * columns {
			if input[move_offset + index] < 1 || input[move_offset + index] > 100 { return -1 }
		}
		mut costs := [32]i64{}
		mut next_costs := [32]i64{}
		for row in 0 .. rows - 1 {
			for target in 0 .. columns { next_costs[target] = 1_000_000_000 }
			for column in 0 .. columns {
				value := int(input[2 + row * columns + column])
				base := costs[column] + i64(value)
				for target in 0 .. columns {
					candidate := base + input[move_offset + value * columns + target]
					if candidate < next_costs[target] { next_costs[target] = candidate }
				}
			}
			for column in 0 .. columns { costs[column] = next_costs[column] }
		}
		last_row := 2 + (rows - 1) * columns
		mut minimum := i64(1_000_000_000)
		for column in 0 .. columns {
			candidate := costs[column] + input[last_row + column]
			if candidate < minimum { minimum = candidate }
		}
		return minimum
	}
}
