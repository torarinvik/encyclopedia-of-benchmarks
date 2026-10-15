package midpoint_circle

import "core:c"

plotted_point_count :: proc(radius: i64) -> i64 {
	if radius == 0 do return 1
	x := radius
	y: i64 = 0
	decision := 1 - radius
	count: i64 = 8
	for x > y {
		y += 1
		if decision <= 0 {
			decision += 2*y + 1
		} else {
			x -= 1
			decision += 2*y - 2*x + 1
		}
		count += 8
	}
	return count
}

append_symmetric_points :: proc(output: [^]u8, point_index: i64,
	center_x, center_y, x, y: i64) -> i64 {
	offsets := [8][2]i64{{x, y}, {-x, y}, {x, -y}, {-x, -y},
		{y, x}, {-y, x}, {y, -x}, {-y, -x}}
	for point in 0 ..< 8 {
		point_x := u32(i32(center_x + offsets[point][0]))
		point_y := u32(i32(center_y + offsets[point][1]))
		byte_index := int((point_index + i64(point)) * 8)
		for byte := 0; byte < 4; byte += 1 {
			output[byte_index + byte] = u8((point_x >> u32(byte * 8)) & 255)
			output[byte_index + 4 + byte] = u8((point_y >> u32(byte * 8)) & 255)
		}
	}
	return point_index + 8
}

@(export)
midpoint_circle :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length != 3 || values == nil do return -1
	center_x, center_y, radius := values[0], values[1], values[2]
	if center_x < -10000 || center_x > 10000 || center_y < -10000 || center_y > 10000 ||
		radius < 0 || radius > 1000 do return -1

	count := plotted_point_count(radius)
	if output == nil || output_capacity < c.size_t(count * 8) do return -2
	if radius == 0 {
		x_bits, y_bits := u32(i32(center_x)), u32(i32(center_y))
		for byte := 0; byte < 4; byte += 1 {
			output[byte] = u8((x_bits >> u32(byte * 8)) & 255)
			output[4 + byte] = u8((y_bits >> u32(byte * 8)) & 255)
		}
		return 1
	}

	point_index: i64 = 0
	x, y := radius, i64(0)
	decision := 1 - radius
	point_index = append_symmetric_points(output, point_index, center_x, center_y, x, y)
	for x > y {
		y += 1
		if decision <= 0 {
			decision += 2*y + 1
		} else {
			x -= 1
			decision += 2*y - 2*x + 1
		}
		point_index = append_symmetric_points(output, point_index, center_x, center_y, x, y)
	}
	return point_index
}
