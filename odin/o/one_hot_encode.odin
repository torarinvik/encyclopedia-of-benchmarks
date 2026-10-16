package one_hot_encode

import "core:c"

@(export)
one_hot_encode :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 33 || values[0] < 1 || values[0] > 32 do return -1
	rows := int(values[0]); if int(length) != rows+1 do return -1
	present: [26]bool
	for i := 0; i < rows; i += 1 { if values[i+1] < 0 || values[i+1] > 25 do return -1; present[int(values[i+1])] = true }
	map: [26]int
	cols := 0
	for i := 0; i < 26; i += 1 { if present[i] { map[i] = cols; cols += 1 } }
	needed := rows*cols
	if c.size_t(needed) > capacity || (needed > 0 && output == nil) do return -2
	for r := 0; r < rows; r += 1 { for col := 0; col < cols; col += 1 { if map[int(values[r+1])] == col { output[r*cols+col] = 1 } else { output[r*cols+col] = 0 } } }
	return i64(needed)
}
