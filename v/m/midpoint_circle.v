module midpoint_circle

fn plotted_point_count(radius i64) i64 {
	if radius == 0 { return 1 }
	mut x := radius
	mut y := i64(0)
	mut decision := 1 - radius
	mut count := i64(8)
	for x > y {
		y++
		if decision <= 0 {
			decision += 2 * y + 1
		} else {
		x--
			decision += 2 * y - 2 * x + 1
		}
		count += 8
	}
	return count
}

fn append_symmetric_points(mut output &u8, point_index int, center_x, center_y, x, y i64) int {
	offsets := [8][2]i64{{x, y}, {-x, y}, {x, -y}, {-x, -y},
		{y, x}, {-y, x}, {y, -x}, {-y, -x}}
	mut next_index := point_index
	for point, offset in offsets {
		x_bits := u32(i32(center_x + offset[0]))
		y_bits := u32(i32(center_y + offset[1]))
		byte_index := next_index * 8
		for byte in 0 .. 4 {
			unsafe {
				output[byte_index + byte] = u8((x_bits >> (byte * 8)) & 255)
				output[byte_index + 4 + byte] = u8((y_bits >> (byte * 8)) & 255)
			}
		}
		next_index++
	}
	return next_index
}

@[export: 'midpoint_circle']
pub fn midpoint_circle(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length != 3 || unsafe { values == nil } { return -1 }
	unsafe {
		center_x := values[0]
		center_y := values[1]
		radius := values[2]
		if center_x < -10000 || center_x > 10000 || center_y < -10000 || center_y > 10000 ||
			radius < 0 || radius > 1000 { return -1 }

		count := plotted_point_count(radius)
		if output == nil || output_capacity < usize(count * 8) { return -2 }
		if radius == 0 {
			x_bits := u32(i32(center_x))
			y_bits := u32(i32(center_y))
			for byte in 0 .. 4 {
				output[byte] = u8((x_bits >> (byte * 8)) & 255)
				output[4 + byte] = u8((y_bits >> (byte * 8)) & 255)
			}
			return 1
		}

		mut point_index := 0
		mut x := radius
		mut y := i64(0)
		mut decision := 1 - radius
		point_index = append_symmetric_points(mut output, point_index, center_x, center_y, x, y)
		for x > y {
			y++
			if decision <= 0 {
				decision += 2 * y + 1
			} else {
				x--
				decision += 2 * y - 2 * x + 1
			}
			point_index = append_symmetric_points(mut output, point_index, center_x, center_y, x, y)
		}
		return i64(point_index)
	}
}
