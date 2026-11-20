module fourier_motzkin_feasibility

const max_variables = 3
const max_inequalities = 6
const max_rows = 128
const max_parseable = 27
const row_width = 4

@[export: 'fourier_motzkin_feasibility']
pub fn fourier_motzkin_feasibility(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > usize(max_parseable) { return -1 }
		dimension_value, count_value := input[0], input[1]
		if dimension_value < 1 || dimension_value > max_variables ||
			count_value < 1 || count_value > max_inequalities { return -1 }
		dimension, count := int(dimension_value), int(count_value)
		if int(length) != 2 + count * (dimension + 1) { return -1 }

		mut current := [max_rows * row_width]i64{}
		mut next_rows := [max_rows * row_width]i64{}
		mut offset := 2
		for row in 0 .. count {
			for coordinate in 0 .. dimension {
				value := input[offset]
				offset++
				if value < -3 || value > 3 { return -1 }
				current[row * row_width + coordinate] = value
			}
			bound := input[offset]
			offset++
			if bound < -6 || bound > 6 { return -1 }
			current[row * row_width + 3] = bound
		}

		mut row_count := count
		for variable in 0 .. dimension {
			mut next_count := 0
			for row in 0 .. row_count {
				if current[row * row_width + variable] == 0 {
					for column in 0 .. row_width {
						next_rows[next_count * row_width + column] = current[row * row_width + column]
					}
					next_count++
				}
			}
			for upper in 0 .. row_count {
				positive := current[upper * row_width + variable]
				if positive <= 0 { continue }
				for lower in 0 .. row_count {
					negative := current[lower * row_width + variable]
					if negative >= 0 { continue }
					if next_count >= max_rows { return -1 }
					upper_scale, lower_scale := positive, -negative
					for coordinate in 0 .. dimension {
						if coordinate == variable {
							next_rows[next_count * row_width + coordinate] = 0
						} else {
							next_rows[next_count * row_width + coordinate] =
								lower_scale * current[upper * row_width + coordinate] +
								upper_scale * current[lower * row_width + coordinate]
						}
					}
					next_rows[next_count * row_width + 3] =
						lower_scale * current[upper * row_width + 3] + upper_scale * current[lower * row_width + 3]
					next_count++
				}
			}
			for row in 0 .. next_count {
				for column in 0 .. row_width {
					current[row * row_width + column] = next_rows[row * row_width + column]
					next_rows[row * row_width + column] = 0
				}
			}
			row_count = next_count
		}
		for row in 0 .. row_count {
			if current[row * row_width + 3] < 0 { return 0 }
		}
		return 1
	}
}
