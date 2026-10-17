module sierpinski_triangle

fn write_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

fn emit_segment(mut output &u8, mut position &int, x0 i64, y0 i64, x1 i64, y1 i64) {
	write_i64_le(mut output, position[0], x0)
	position[0] += 8
	write_i64_le(mut output, position[0], y0)
	position[0] += 8
	write_i64_le(mut output, position[0], x1)
	position[0] += 8
	write_i64_le(mut output, position[0], y1)
	position[0] += 8
}

fn draw_triangle(mut output &u8, mut position &int,
	x1 i64, y1 i64, x2 i64, y2 i64, x3 i64, y3 i64, depth i64) {
	emit_segment(mut output, mut position, x1, y1, x2, y2)
	emit_segment(mut output, mut position, x2, y2, x3, y3)
	emit_segment(mut output, mut position, x3, y3, x1, y1)
	if depth == 0 { return }
	abx := (x1 + x2) / 2
	aby := (y1 + y2) / 2
	acx := (x1 + x3) / 2
	acy := (y1 + y3) / 2
	bcx := (x2 + x3) / 2
	bcy := (y2 + y3) / 2
	draw_triangle(mut output, mut position, x1, y1, abx, aby, acx, acy, depth - 1)
	draw_triangle(mut output, mut position, x2, y2, abx, aby, bcx, bcy, depth - 1)
	draw_triangle(mut output, mut position, x3, y3, bcx, bcy, acx, acy, depth - 1)
}

@[export: 'sierpinski_triangle']
pub fn sierpinski_triangle(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length != 1 { return -1 }
	depth := unsafe { input[0] }
	if depth < 0 || depth > 4 { return -1 }
	mut calls := 1
	for _ in 0 .. int(depth) { calls = calls * 3 + 1 }
	needed := calls * 96
	if needed > 11616 { return -1 }
	if unsafe { output == nil } || capacity < usize(needed) { return -2 }
	mut position := 0
	draw_triangle(mut output, mut position, -2800, -2000, 0, 2800, 2800, -2000, depth)
	return i64(needed)
}
