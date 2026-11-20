package strange_printer_ii

import "core:c"

MAX_ROWS :: 6
MAX_COLUMNS :: 6
MAX_COLORS :: 6
COLOR_SIDE :: 7

@(export, link_name="strange_printer_ii")
strange_printer_ii :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 39 do return -1
	rows_value := input[0]
	columns_value := input[1]
	if rows_value < 1 || rows_value > MAX_ROWS || columns_value < 1 || columns_value > MAX_COLUMNS do return -1
	rows := int(rows_value)
	columns := int(columns_value)
	if length != c.size_t(2 + rows * columns) do return -1
	for cell := 0; cell < rows * columns; cell += 1 {
		if input[cell + 2] < 1 || input[cell + 2] > MAX_COLORS do return -1
	}

	first_row: [COLOR_SIDE]i64
	last_row: [COLOR_SIDE]i64
	first_column: [COLOR_SIDE]i64
	last_column: [COLOR_SIDE]i64
	outgoing: [COLOR_SIDE]i64
	indegree: [COLOR_SIDE]i64
	queue: [COLOR_SIDE]i64
	for color := 0; color < COLOR_SIDE; color += 1 {
		first_row[color] = rows_value
		last_row[color] = -1
		first_column[color] = columns_value
		last_column[color] = -1
		outgoing[color] = 0
		indegree[color] = 0
		queue[color] = 0
	}
	for row := 0; row < rows; row += 1 {
		for column := 0; column < columns; column += 1 {
			color := int(input[2 + row * columns + column])
			if i64(row) < first_row[color] do first_row[color] = i64(row)
			if i64(row) > last_row[color] do last_row[color] = i64(row)
			if i64(column) < first_column[color] do first_column[color] = i64(column)
			if i64(column) > last_column[color] do last_column[color] = i64(column)
		}
	}

	present_count: i64 = 0
	for color := 1; color <= MAX_COLORS; color += 1 {
		if last_row[color] < 0 do continue
		present_count += 1
		for row := int(first_row[color]); row <= int(last_row[color]); row += 1 {
			for column := int(first_column[color]); column <= int(last_column[color]); column += 1 {
				covered := int(input[2 + row * columns + column])
				bit := i64(1) << covered
				if covered != color && (outgoing[color] & bit) == 0 {
					outgoing[color] |= bit
					indegree[covered] += 1
				}
			}
		}
	}
	head := 0
	tail := 0
	for color := 1; color <= MAX_COLORS; color += 1 {
		if last_row[color] >= 0 && indegree[color] == 0 {
			queue[tail] = i64(color)
			tail += 1
		}
	}
	processed: i64 = 0
	for head < tail {
		color := int(queue[head])
		head += 1
		processed += 1
		for later := 1; later <= MAX_COLORS; later += 1 {
			if (outgoing[color] & (i64(1) << later)) != 0 {
				indegree[later] -= 1
				if indegree[later] == 0 {
					queue[tail] = i64(later)
					tail += 1
				}
			}
		}
	}
	if processed == present_count do return 1
	return 0
}
