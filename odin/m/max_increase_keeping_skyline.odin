package max_increase_keeping_skyline

import "core:c"

MAX_GRID_SIZE :: 50

// Return the total allowable increase while preserving row and column skylines.
@(export)
max_increase_keeping_skyline :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 1 + MAX_GRID_SIZE * MAX_GRID_SIZE do return -1
	if values[0] < 2 || values[0] > MAX_GRID_SIZE do return -1
	size := int(values[0])
	if length != c.size_t(1 + size * size) do return -1

	row_max: [MAX_GRID_SIZE]i64
	column_max: [MAX_GRID_SIZE]i64
	for row := 0; row < size; row += 1 {
		for column := 0; column < size; column += 1 {
			height := values[1 + row * size + column]
			if height < 0 || height > 100 do return -1
			if height > row_max[row] do row_max[row] = height
			if height > column_max[column] do column_max[column] = height
		}
	}

	total := i64(0)
	for row := 0; row < size; row += 1 {
		for column := 0; column < size; column += 1 {
			height := values[1 + row * size + column]
			skyline := row_max[row]
			if column_max[column] < skyline do skyline = column_max[column]
			total += skyline - height
		}
	}
	return total
}
