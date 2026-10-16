module sierpinski_carpet

fn write_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

fn is_filled(row_start int, col_start int) bool {
	mut row := row_start
	mut col := col_start
	for row != 0 || col != 0 {
		if row % 3 == 1 && col % 3 == 1 { return false }
		row /= 3
		col /= 3
	}
	return true
}

@[export: 'sierpinski_carpet']
pub fn sierpinski_carpet(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length != 3 { return -1 }
	depth := unsafe { input[0] }
	filled := unsafe { input[1] }
	hole := unsafe { input[2] }
	if depth < 0 || depth > 4 || filled < 32 || filled > 126 ||
		hole < 32 || hole > 126 || filled == hole { return -1 }
	mut side := 1
	for _ in 0 .. int(depth) { side *= 3 }
	needed := 8 + side * side + side - 1
	if unsafe { output == nil } || capacity < usize(needed) { return -2 }

	write_i64_le(mut output, 0, i64(side))
	mut out := 8
	for row in 0 .. side {
		for col in 0 .. side {
			unsafe { output[out] = if is_filled(row, col) { u8(filled) } else { u8(hole) } }
			out++
		}
		if row + 1 < side {
			unsafe { output[out] = u8(10) }
			out++
		}
	}
	return i64(needed)
}
