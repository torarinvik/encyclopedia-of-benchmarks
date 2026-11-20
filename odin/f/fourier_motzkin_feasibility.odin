package fourier_motzkin_feasibility

import "core:c"

MAX_VARIABLES :: 3
MAX_INEQUALITIES :: 6
MAX_ROWS :: 128
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(27)
ROW_WIDTH :: 4

@(export)
fourier_motzkin_feasibility :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	dimension_value, count_value := input[0], input[1]
	if dimension_value < 1 || dimension_value > MAX_VARIABLES ||
		count_value < 1 || count_value > MAX_INEQUALITIES do return -1
	dimension, count := int(dimension_value), int(count_value)
	if length != c.size_t(2 + count*(dimension+1)) do return -1

	var current: [MAX_ROWS * ROW_WIDTH]i64
	var next_rows: [MAX_ROWS * ROW_WIDTH]i64
	offset := 2
	for row := 0; row < count; row += 1 {
		for coordinate := 0; coordinate < dimension; coordinate += 1 {
			value := input[offset]
			offset += 1
			if value < -3 || value > 3 do return -1
			current[row*ROW_WIDTH+coordinate] = value
		}
		bound := input[offset]
		offset += 1
		if bound < -6 || bound > 6 do return -1
		current[row*ROW_WIDTH+3] = bound
	}

	row_count := count
	for variable := 0; variable < dimension; variable += 1 {
		next_count := 0
		for row := 0; row < row_count; row += 1 {
			if current[row*ROW_WIDTH+variable] == 0 {
				for column := 0; column < ROW_WIDTH; column += 1 {
					next_rows[next_count*ROW_WIDTH+column] = current[row*ROW_WIDTH+column]
				}
				next_count += 1
			}
		}
		for upper := 0; upper < row_count; upper += 1 {
			positive := current[upper*ROW_WIDTH+variable]
			if positive <= 0 do continue
			for lower := 0; lower < row_count; lower += 1 {
				negative := current[lower*ROW_WIDTH+variable]
				if negative >= 0 do continue
				if next_count >= MAX_ROWS do return -1
				upper_scale, lower_scale := positive, -negative
				for coordinate := 0; coordinate < dimension; coordinate += 1 {
					if coordinate == variable {
						next_rows[next_count*ROW_WIDTH+coordinate] = 0
					} else {
						next_rows[next_count*ROW_WIDTH+coordinate] =
							lower_scale*current[upper*ROW_WIDTH+coordinate] +
							upper_scale*current[lower*ROW_WIDTH+coordinate]
					}
				}
				next_rows[next_count*ROW_WIDTH+3] =
					lower_scale*current[upper*ROW_WIDTH+3] + upper_scale*current[lower*ROW_WIDTH+3]
				next_count += 1
			}
		}
		for row := 0; row < next_count; row += 1 {
			for column := 0; column < ROW_WIDTH; column += 1 {
				current[row*ROW_WIDTH+column] = next_rows[row*ROW_WIDTH+column]
				next_rows[row*ROW_WIDTH+column] = 0
			}
		}
		row_count = next_count
	}
	for row := 0; row < row_count; row += 1 {
		if current[row*ROW_WIDTH+3] < 0 do return 0
	}
	return 1
}
