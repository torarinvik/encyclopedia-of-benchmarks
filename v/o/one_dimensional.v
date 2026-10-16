module one_dimensional

@[export: 'one_dimensional']
pub fn one_dimensional(values &i64, length usize, output &u8, capacity usize) i64 {
	if length != 1 { return -1 }
	code := unsafe { values[0] }
	if code < 0 || code > 11111111 { return -1 }
	mut digits := [8]u8{}
	mut rules := [8]u8{}
	mut x := code
	mut count := 0
	for {
		d := x % 10
		if d > 1 { return -1 }
		digits[count] = u8(d); count++; x /= 10
		if x == 0 { break }
		if count == 8 { return -1 }
	}
	for i in 0 .. count { rules[8-count+i] = digits[count-1-i] }
	mut cells := [17][31]u8{}
	cells[0][15] = 1
	for r in 0 .. 16 { for c in 0 .. 31 {
		left := if c > 0 { int(cells[r][c-1]) } else { 0 }
		center := int(cells[r][c])
		right := if c < 30 { int(cells[r][c+1]) } else { 0 }
		cells[r+1][c] = rules[7-((left << 2) | (center << 1) | right)]
	} }
	if capacity < 1581 || isnil(output) { return -2 }
	mut pos := 0
	for row in cells { for cell in row {
		color := if cell == 1 { u8(0) } else { u8(255) }
		unsafe { output[pos] = color; output[pos+1] = color; output[pos+2] = color }
		pos += 3
	} }
	return i64(pos)
}
