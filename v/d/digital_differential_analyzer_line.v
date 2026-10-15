module digital_differential_analyzer_line

fn round_ties_to_even(value f64) i64 {
	mut lower := i64(value)
	if f64(lower) > value { lower-- }
	fraction := value - f64(lower)
	if fraction > 0.5 || (fraction == 0.5 && lower % 2 != 0) { lower++ }
	return lower
}

fn write_i32_le(output &u8, position_value int, value i64) int {
	bits := u32(i32(value))
	mut position := position_value
	for shift := 0; shift < 32; shift += 8 {
		unsafe { output[position] = u8((bits >> shift) & 255) }
		position++
	}
	return position
}

@[export: 'digital_differential_analyzer_line']
pub fn digital_differential_analyzer_line(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length != 4 { return -1 }
	unsafe {
		for index in 0 .. 4 {
			if values[index] < -1000000 || values[index] > 1000000 { return -1 }
		}
		dx := values[2] - values[0]
		dy := values[3] - values[1]
		mut abs_dx := dx
		mut abs_dy := dy
		if abs_dx < 0 { abs_dx = -abs_dx }
		if abs_dy < 0 { abs_dy = -abs_dy }
		steps := if abs_dx > abs_dy { abs_dx } else { abs_dy }
		if steps == 0 || steps > 4096 { return -1 }
		output_bytes := usize(steps * 8)
		if output_capacity < output_bytes { return -2 }
		x_increment := f64(dx) / f64(steps)
		y_increment := f64(dy) / f64(steps)
		mut x := f64(values[0])
		mut y := f64(values[1])
		mut position := 0
		for step := i64(0); step < steps; step++ {
			x += x_increment
			y += y_increment
			position = write_i32_le(output, position, round_ties_to_even(x))
			position = write_i32_le(output, position, round_ties_to_even(y))
		}
		return i64(output_bytes)
	}
}
