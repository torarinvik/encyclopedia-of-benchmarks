module bresenham_line

const coordinate_limit = i64(1_000_000)
const max_step = i64(4096)

fn raster_point_count(x0, y0, x1, y1 i64) i64 {
	mut x := x0
	mut y := y0
	dx := if x1 >= x0 { x1 - x0 } else { x0 - x1 }
	distance_y := if y1 >= y0 { y1 - y0 } else { y0 - y1 }
	dy := -distance_y
	sx := if x0 < x1 { i64(1) } else { i64(-1) }
	sy := if y0 < y1 { i64(1) } else { i64(-1) }
	mut error := dx + dy
	mut count := i64(0)
	for {
		count++
		if x == x1 && y == y1 { break }
		e2 := 2 * error
		if e2 > dy {
			error += dy
			x += sx
		}
		if e2 < dx {
			error += dx
			y += sy
		}
	}
	return count
}

fn write_point(mut output &u8, point_index int, x, y i64) {
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

fn rasterize(mut output &u8, x0, y0, x1, y1 i64) {
	mut x := x0
	mut y := y0
	dx := if x1 >= x0 { x1 - x0 } else { x0 - x1 }
	distance_y := if y1 >= y0 { y1 - y0 } else { y0 - y1 }
	dy := -distance_y
	sx := if x0 < x1 { i64(1) } else { i64(-1) }
	sy := if y0 < y1 { i64(1) } else { i64(-1) }
	mut error := dx + dy
	mut point_index := 0
	for {
		write_point(mut output, point_index, x, y)
		point_index++
		if x == x1 && y == y1 { break }
		e2 := 2 * error
		if e2 > dy {
			error += dy
			x += sx
		}
		if e2 < dx {
			error += dx
			y += sy
		}
	}
}

@[export: 'bresenham_line']
pub fn bresenham_line(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length != 4 || unsafe { values == nil } { return -1 }
	unsafe {
		x0 := values[0]
		y0 := values[1]
		x1 := values[2]
		y1 := values[3]
		if x0 < -coordinate_limit || x0 > coordinate_limit || y0 < -coordinate_limit ||
			y0 > coordinate_limit || x1 < -coordinate_limit || x1 > coordinate_limit ||
			y1 < -coordinate_limit || y1 > coordinate_limit { return -1 }
		if (x1 - x0 < -max_step || x1 - x0 > max_step) ||
			(y1 - y0 < -max_step || y1 - y0 > max_step) { return -1 }
		byte_count := raster_point_count(x0, y0, x1, y1) * 8
		if output == nil || output_capacity < usize(byte_count) { return -2 }
		rasterize(mut output, x0, y0, x1, y1)
		return byte_count
	}
}
