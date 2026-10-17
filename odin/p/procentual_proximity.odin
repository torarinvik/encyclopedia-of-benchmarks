package procentual_proximity

import "core:c"

MAX_ROWS :: 64
MAX_COLUMNS :: 8

write_f64_le :: proc "contextless" (output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> u64(8 * byte))
	}
}

@(export)
procentual_proximity :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 522 do return -1
	row_value := input[0]
	column_value := input[1]
	if row_value < 1 || row_value > MAX_ROWS || column_value < 1 || column_value > MAX_COLUMNS do return -1
	rows := int(row_value)
	columns := int(column_value)
	if int(length) != 2 + columns + rows * columns do return -1
	for column := 0; column < columns; column += 1 {
		weight := input[2 + column]
		if weight != 0 && weight != 1 do return -1
	}
	data: [MAX_ROWS][MAX_COLUMNS]f64
	for row := 0; row < rows; row += 1 {
		for column := 0; column < columns; column += 1 {
			value := input[2 + columns + row * columns + column]
			if value < -10000 || value > 10000 do return -1
			data[row][column] = f64(value)
		}
	}
	output_length := rows * (columns + 1) * 8
	if output == nil || capacity < c.size_t(output_length) do return -2

	scores: [MAX_ROWS]f64
	for column := 0; column < columns; column += 1 {
		minimum := data[0][column]
		maximum := data[0][column]
		for row := 1; row < rows; row += 1 {
			if data[row][column] < minimum do minimum = data[row][column]
			if data[row][column] > maximum do maximum = data[row][column]
		}
		weight := input[2 + column]
		if minimum == maximum {
			if weight == 0 {
				for row := 0; row < rows; row += 1 do scores[row] += 1.0
			}
		} else {
			value_range := maximum - minimum
			for row := 0; row < rows; row += 1 {
				item_score := (data[row][column] - minimum) / value_range
				if weight == 0 do item_score = 1.0 - item_score
				scores[row] = scores[row] + item_score
			}
		}
	}
	offset := 0
	for row := 0; row < rows; row += 1 {
		for column := 0; column < columns; column += 1 {
			write_f64_le(output, offset, data[row][column])
			offset += 8
		}
		write_f64_le(output, offset, scores[row])
		offset += 8
	}
	return i64(output_length)
}
