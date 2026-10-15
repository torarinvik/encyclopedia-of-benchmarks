package midpoint_ellipse

import "core:c"

ellipse_point_count :: proc(a, b: i64) -> i64 {
	if a == 0 do return 2*b + 1
	if b == 0 do return 2*a + 1
	aa, bb := a*a, b*b
	x, y := i64(0), b
	dx, dy := 2*bb*x, 2*aa*y
	d1 := f64(bb) - f64(aa*b) + 0.25*f64(aa)
	count: i64 = 0
	for dx < dy {
		count += 4
		if d1 < 0 {
			x += 1
			dx += 2*bb
			d1 += f64(dx + bb)
		} else {
			x += 1
			y -= 1
			dx += 2*bb
			dy -= 2*aa
			d1 += f64(dx - dy + bb)
		}
	}
	d2 := f64(bb)*(f64(x)+0.5)*(f64(x)+0.5) + f64(aa)*f64(y-1)*f64(y-1) - f64(aa*bb)
	for y >= 0 {
		count += 4
		if d2 > 0 {
			y -= 1
			dy -= 2*aa
			d2 += f64(aa - dy)
		} else {
			y -= 1
			x += 1
			dx += 2*bb
			dy -= 2*aa
			d2 += f64(dx - dy + aa)
		}
	}
	return count
}

write_point :: proc(output: [^]u8, point_index, x, y: i64) {
	x_bits, y_bits := u32(i32(x)), u32(i32(y))
	byte_index := int(point_index * 8)
	for byte := 0; byte < 4; byte += 1 {
		output[byte_index + byte] = u8((x_bits >> u32(byte*8)) & 255)
		output[byte_index + 4 + byte] = u8((y_bits >> u32(byte*8)) & 255)
	}
}

emit_quadrant :: proc(output: [^]u8, point_index, center_x, center_y, x, y: i64) {
	write_point(output, point_index, center_x+x, center_y+y)
	write_point(output, point_index+1, center_x-x, center_y+y)
	write_point(output, point_index+2, center_x+x, center_y-y)
	write_point(output, point_index+3, center_x-x, center_y-y)
}

@(export)
midpoint_ellipse :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length != 4 || values == nil do return -1
	cx, cy, a, b := values[0], values[1], values[2], values[3]
	if cx < -10000 || cx > 10000 || cy < -10000 || cy > 10000 ||
		a < 0 || a > 100 || b < 0 || b > 100 do return -1
	count := ellipse_point_count(a, b)
	if a == 0 && b == 0 { count = 1 }
	if output == nil || output_capacity < c.size_t(count * 8) do return -2
	if a == 0 && b == 0 {
		write_point(output, 0, cx, cy)
		return 1
	}
	if a == 0 {
		for offset in 0 ..< 2*b+1 do write_point(output, offset, cx, cy-b+offset)
		return count
	}
	if b == 0 {
		for offset in 0 ..< 2*a+1 do write_point(output, offset, cx-a+offset, cy)
		return count
	}

	aa, bb := a*a, b*b
	x, y := i64(0), b
	dx, dy := 2*bb*x, 2*aa*y
	d1 := f64(bb) - f64(aa*b) + 0.25*f64(aa)
	point_index: i64 = 0
	for dx < dy {
		emit_quadrant(output, point_index, cx, cy, x, y)
		point_index += 4
		if d1 < 0 {
			x += 1
			dx += 2*bb
			d1 += f64(dx + bb)
		} else {
			x += 1
			y -= 1
			dx += 2*bb
			dy -= 2*aa
			d1 += f64(dx - dy + bb)
		}
	}
	d2 := f64(bb)*(f64(x)+0.5)*(f64(x)+0.5) + f64(aa)*f64(y-1)*f64(y-1) - f64(aa*bb)
	for y >= 0 {
		emit_quadrant(output, point_index, cx, cy, x, y)
		point_index += 4
		if d2 > 0 {
			y -= 1
			dy -= 2*aa
			d2 += f64(aa - dy)
		} else {
			y -= 1
			x += 1
			dx += 2*bb
			dy -= 2*aa
			d2 += f64(dx - dy + aa)
		}
	}
	return count
}
