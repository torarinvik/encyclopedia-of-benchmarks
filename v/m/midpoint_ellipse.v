module midpoint_ellipse

fn ellipse_point_count(a i64, b i64) int {
	if a == 0 { return int(2 * b + 1) }
	if b == 0 { return int(2 * a + 1) }
	aa := a * a
	bb := b * b
	mut x := i64(0)
	mut y := b
	mut dx := 2 * bb * x
	mut dy := 2 * aa * y
	mut d1 := f64(bb) - f64(aa * b) + 0.25 * f64(aa)
	mut count := 0
	for dx < dy {
		count += 4
		if d1 < 0.0 {
			x++
			dx += 2 * bb
			d1 += f64(dx + bb)
		} else {
			x++
			y--
			dx += 2 * bb
			dy -= 2 * aa
			d1 += f64(dx - dy + bb)
		}
	}
	mut d2 := f64(bb) * (f64(x) + 0.5) * (f64(x) + 0.5) +
		f64(aa) * f64(y - 1) * f64(y - 1) - f64(aa * bb)
	for y >= 0 {
		count += 4
		if d2 > 0.0 {
			y--
			dy -= 2 * aa
			d2 += f64(aa - dy)
		} else {
			y--
			x++
			dx += 2 * bb
			dy -= 2 * aa
			d2 += f64(dx - dy + aa)
		}
	}
	return count
}

fn write_point(mut output &u8, point_index int, x i64, y i64) {
	x_bits := u32(i32(x))
	y_bits := u32(i32(y))
	byte_index := point_index * 8
	for byte in 0 .. 4 {
		unsafe {
			output[byte_index + byte] = u8((x_bits >> (byte * 8)) & 255)
			output[byte_index + 4 + byte] = u8((y_bits >> (byte * 8)) & 255)
		}
	}
}

fn emit_quadrant(mut output &u8, point_index int, center_x i64, center_y i64, x i64, y i64) {
	write_point(mut output, point_index, center_x + x, center_y + y)
	write_point(mut output, point_index + 1, center_x - x, center_y + y)
	write_point(mut output, point_index + 2, center_x + x, center_y - y)
	write_point(mut output, point_index + 3, center_x - x, center_y - y)
}

@[export: 'midpoint_ellipse']
pub fn midpoint_ellipse(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length != 4 || unsafe { values == nil } { return -1 }
	unsafe {
		center_x := values[0]
		center_y := values[1]
		a := values[2]
		b := values[3]
		if center_x < -10000 || center_x > 10000 || center_y < -10000 || center_y > 10000 ||
			a < 0 || a > 100 || b < 0 || b > 100 { return -1 }
		count := if a == 0 && b == 0 { 1 } else { ellipse_point_count(a, b) }
		if output == nil || output_capacity < usize(count * 8) { return -2 }
		if a == 0 && b == 0 {
			write_point(mut output, 0, center_x, center_y)
			return 1
		}
		if a == 0 {
			for offset in 0 .. count {
				write_point(mut output, offset, center_x, center_y - b + i64(offset))
			}
			return i64(count)
		}
		if b == 0 {
			for offset in 0 .. count {
				write_point(mut output, offset, center_x - a + i64(offset), center_y)
			}
			return i64(count)
		}

		aa := a * a
		bb := b * b
		mut x := i64(0)
		mut y := b
		mut dx := 2 * bb * x
		mut dy := 2 * aa * y
		mut d1 := f64(bb) - f64(aa * b) + 0.25 * f64(aa)
		mut point_index := 0
		for dx < dy {
			emit_quadrant(mut output, point_index, center_x, center_y, x, y)
			point_index += 4
			if d1 < 0.0 {
				x++
				dx += 2 * bb
				d1 += f64(dx + bb)
			} else {
				x++
				y--
				dx += 2 * bb
				dy -= 2 * aa
				d1 += f64(dx - dy + bb)
			}
		}
		mut d2 := f64(bb) * (f64(x) + 0.5) * (f64(x) + 0.5) +
			f64(aa) * f64(y - 1) * f64(y - 1) - f64(aa * bb)
		for y >= 0 {
			emit_quadrant(mut output, point_index, center_x, center_y, x, y)
			point_index += 4
			if d2 > 0.0 {
				y--
				dy -= 2 * aa
				d2 += f64(aa - dy)
			} else {
				y--
				x++
				dx += 2 * bb
				dy -= 2 * aa
				d2 += f64(dx - dy + aa)
			}
		}
		return i64(count)
	}
}
