module ddaline

fn java_round(value f64) i64 {
	shifted := value + 0.5
	mut rounded := i64(shifted)
	if f64(rounded) > shifted { rounded-- }
	return rounded
}

fn write_i64(output &u8, mut position &int, value i64) {
	for shift in 0 .. 8 {
		unsafe { output[position] = u8((value >> (shift * 8)) & 255) }
		position++
	}
}

@[export: 'ddaline']
pub fn ddaline(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length != 4 { return -1 }
	unsafe {
		for i in 0 .. 4 { if input[i] < -128 || input[i] > 128 { return -1 } }
		dx, dy := input[2] - input[0], input[3] - input[1]
		mut ax := dx; if ax < 0 { ax = -ax }
		mut ay := dy; if ay < 0 { ay = -ay }
		steps := if ax > ay { ax } else { ay }
		if steps > 256 { return -1 }
		output_bytes := (int(steps) + 1) * 16
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut position := 0
		if steps == 0 { write_i64(output, mut position, input[0]); write_i64(output, mut position, input[1]); return 16 }
		x_increment := f64(dx) / f64(steps)
		y_increment := f64(dy) / f64(steps)
		mut x, mut y := f64(input[0]), f64(input[1])
		for _ in 0 .. int(steps) + 1 {
			write_i64(output, mut position, java_round(x))
			write_i64(output, mut position, java_round(y))
			x += x_increment
			y += y_increment
		}
		return i64(output_bytes)
	}
}
