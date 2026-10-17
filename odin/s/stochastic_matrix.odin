package stochastic_matrix

import "core:c"

MAX_DIMENSION :: 63
MAX_INPUT_VALUES :: 3972
MAX_ABS_CELL :: i64(1_000_000_000_000)
CELL_SCALE :: 1.0e12
TOLERANCE :: 1.0e-9

@(export)
stochastic_matrix :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT_VALUES do return -1
	mode := input[0]
	rows_value := input[1]
	columns_value := input[2]
	if (mode != 0 && mode != 1) || rows_value < 1 || rows_value > MAX_DIMENSION ||
		columns_value < 1 || columns_value > MAX_DIMENSION do return -1

	rows := int(rows_value)
	columns := int(columns_value)
	total := rows * columns
	if length != c.size_t(3 + total) do return -1

	for index := 0; index < total; index += 1 {
		units := input[3 + index]
		if units < -MAX_ABS_CELL || units > MAX_ABS_CELL do return -1
	}

	if mode == 0 {
		for row := 0; row < rows; row += 1 {
			sum := 0.0
			for column := 0; column < columns; column += 1 {
				value := f64(input[3 + row * columns + column]) / CELL_SCALE
				if value < 0.0 do return 0
				sum += value
			}
			difference := sum - 1.0
			if difference > TOLERANCE || difference < -TOLERANCE do return 0
		}
	} else {
		for column := 0; column < columns; column += 1 {
			sum := 0.0
			for row := 0; row < rows; row += 1 {
				value := f64(input[3 + row * columns + column]) / CELL_SCALE
				if value < 0.0 do return 0
				sum += value
			}
			difference := sum - 1.0
			if difference > TOLERANCE || difference < -TOLERANCE do return 0
		}
	}
	return 1
}
