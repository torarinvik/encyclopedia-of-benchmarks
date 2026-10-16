package transposition_cipher

import "core:c"

MAX_TEXT :: 256
MAX_INPUT :: 259

@(export)
transposition_cipher :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 6 || length > MAX_INPUT do return -1
	mode, key64, n64 := input[0], input[1], input[2]
	if (mode != 0 && mode != 1) || n64 < 3 || n64 > MAX_TEXT || key64 < 2 || key64 >= n64 do return -1
	n, key := int(n64), int(key64)
	if int(length) != 3 + n do return -1
	for i := 0; i < n; i += 1 { if input[3+i] < 0 || input[3+i] > 127 do return -1 }
	if output == nil || output_capacity < c.size_t(n) do return -2
	var transformed: [MAX_TEXT]u8
	if mode == 0 {
		written := 0
		for column := 0; column < key; column += 1 {
			for index := column; index < n; index += key { transformed[written] = u8(input[3+index]); written += 1 }
		}
	} else {
		columns := (n + key - 1) / key
		shaded := columns * key - n
		final_column_rows := key - shaded
		var offsets: [MAX_TEXT]int
		var seen: [MAX_TEXT]int
		total := 0
		for column := 0; column < columns; column += 1 {
			offsets[column] = total
			if column + 1 == columns { total += final_column_rows } else { total += key }
		}
		row, column := 0, 0
		for i := 0; i < n; i += 1 {
			transformed[offsets[column]+seen[column]] = u8(input[3+i])
			seen[column] += 1
			column += 1
			if column == columns || (column == columns-1 && row >= final_column_rows) { column = 0; row += 1 }
		}
	}
	for i := 0; i < n; i += 1 { output[i] = transformed[i] }
	return i64(n)
}
