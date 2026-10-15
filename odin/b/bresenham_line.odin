package bresenham_line

import "core:c"

write_point :: proc(output: [^]u8, point_index: i64, x, y: i64) {
	x_bits, y_bits := u32(i32(x)), u32(i32(y))
	byte_index := int(point_index * 8)
	for byte := 0; byte < 4; byte += 1 {
		output[byte_index + byte] = u8((x_bits >> u32(byte * 8)) & 255)
		output[byte_index + 4 + byte] = u8((y_bits >> u32(byte * 8)) & 255)
	}
}

@(export)
bresenham_line :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length != 4 || values == nil do return -1
	x0, y0, x1, y1 := values[0], values[1], values[2], values[3]
	if x0 < -1000000 || x0 > 1000000 || y0 < -1000000 || y0 > 1000000 ||
		x1 < -1000000 || x1 > 1000000 || y1 < -1000000 || y1 > 1000000 do return -1

	dx := abs(x1 - x0)
	abs_dy := abs(y1 - y0)
	steps := max(dx, abs_dy)
	if steps > 4096 do return -1
	count := steps + 1
	if output == nil || output_capacity < c.size_t(count * 8) do return -2

	x, y := x0, y0
	sx: i64 = -1
	sy: i64 = -1
	if x0 < x1 do sx = 1
	if y0 < y1 do sy = 1
	dy := -abs_dy
	error := dx + dy
	point_index: i64 = 0
	for {
		write_point(output, point_index, x, y)
		point_index += 1
		if x == x1 && y == y1 do break
		doubled_error := 2 * error
		if doubled_error > dy {
			error += dy
			x += sx
		}
		if doubled_error < dx {
			error += dx
			y += sy
		}
	}
	return count
}
