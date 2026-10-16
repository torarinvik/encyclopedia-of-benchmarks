package one_dimensional

import "core:c"

@(export)
one_dimensional :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length != 1 || values[0] < 0 || values[0] > 11111111 do return -1
	digits: [8]u8; rules: [8]u8; x := values[0]; count := 0
	for {
		d := x % 10; if d > 1 do return -1
		digits[count] = u8(d); count += 1; x /= 10
		if x == 0 do break
		if count == 8 do return -1
	}
	for i := 0; i < count; i += 1 { rules[8-count+i] = digits[count-1-i] }
	cells: [17][31]u8; cells[0][15] = 1
	for r := 0; r < 16; r += 1 { for col := 0; col < 31; col += 1 {
		left, right: i64 = 0
		if col > 0 { left = i64(cells[r][col-1]) }; if col < 30 { right = i64(cells[r][col+1]) }
		p := int((left << 2) | (i64(cells[r][col]) << 1) | right); cells[r+1][col] = rules[7-p]
	} }
	if capacity < 1581 || output == nil do return -2
	pos := 0
	for row in cells { for cell in row {
		color: u8 = 255; if cell == 1 { color = 0 }
		output[pos] = color; output[pos+1] = color; output[pos+2] = color; pos += 3
	} }
	return i64(pos)
}
