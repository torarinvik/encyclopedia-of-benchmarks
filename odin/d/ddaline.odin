package ddaline

import "core:c"

java_round :: proc(value: f64) -> i64 {
	shifted := value + 0.5
	rounded := i64(shifted)
	if f64(rounded) > shifted { rounded -= 1 }
	return rounded
}

write_i64 :: proc(output: [^]u8, position: ^usize, value: i64) {
	for shift: u32 = 0; shift < 64; shift += 8 {
		output[position^] = u8((value >> shift) & 255)
		position^ += 1
	}
}

@(export)
ddaline :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 4 do return -1
	for i: usize = 0; i < 4; i += 1 { if input[i] < -128 || input[i] > 128 do return -1 }
	dx, dy := input[2] - input[0], input[3] - input[1]
	ax := dx; if ax < 0 { ax = -ax }
	ay := dy; if ay < 0 { ay = -ay }
	steps := ax; if ay > steps { steps = ay }
	if steps > 256 do return -1
	output_bytes := (usize(steps) + 1) * 16
	if output == nil || capacity < output_bytes do return -2
	position: usize = 0
	if steps == 0 { write_i64(output, &position, input[0]); write_i64(output, &position, input[1]); return 16 }
	x_increment := f64(dx) / f64(steps)
	y_increment := f64(dy) / f64(steps)
	x, y := f64(input[0]), f64(input[1])
	for i: i64 = 0; i <= steps; i += 1 {
		write_i64(output, &position, java_round(x))
		write_i64(output, &position, java_round(y))
		x += x_increment
		y += y_increment
	}
	return i64(output_bytes)
}
