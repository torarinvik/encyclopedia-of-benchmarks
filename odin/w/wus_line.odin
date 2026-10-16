package wus_line

import "core:c"
import "core:math"

COORDINATE_LIMIT :: i64(64)
MAX_PIXELS :: 258

fraction_part :: proc(value: f64) -> f64 { return value - math.floor_f64(value) }
reverse_fraction_part :: proc(value: f64) -> f64 { return 1.0 - fraction_part(value) }

add_pixel :: proc(pixel_x, pixel_y: [^]i64, intensities: [^]f64, count: ^int,
                  x, y: i64, intensity: f64, steep: bool) {
	output_x, output_y := x, y
	if steep { output_x, output_y = y, x }
	clamped := intensity
	if clamped < 0.0 do clamped = 0.0
	if clamped > 1.0 do clamped = 1.0
	pixel_x[count^] = output_x
	pixel_y[count^] = output_y
	intensities[count^] = clamped
	count^ += 1
}

add_endpoint :: proc(pixel_x, pixel_y: [^]i64, intensities: [^]f64, count: ^int,
		x_pixel, y_pixel: i64, y_end, x_gap: f64, steep: bool) {
	fractional_y := fraction_part(y_end)
	complement := reverse_fraction_part(y_end)
	add_pixel(pixel_x, pixel_y, intensities, count, x_pixel, y_pixel, complement*x_gap, steep)
	add_pixel(pixel_x, pixel_y, intensities, count, x_pixel, y_pixel+1, fractional_y*x_gap, steep)
}

write_i32_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u32(i32(value))
	for byte := 0; byte < 4; byte += 1 { output[offset+byte] = u8(bits >> (byte*8)) }
}

write_f64_le :: proc(output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> (byte*8)) }
}

@(export)
wus_line :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length != 4 do return -1
	for index := 0; index < 4; index += 1 {
		if values[index] < -COORDINATE_LIMIT || values[index] > COORDINATE_LIMIT do return -1
	}

	x0, y0, x1, y1 := values[0], values[1], values[2], values[3]
	dy, dx := y1-y0, x1-x0
	if dy < 0 do dy = -dy
	if dx < 0 do dx = -dx
	steep := dy > dx
	if steep { x0, y0 = y0, x0; x1, y1 = y1, x1 }
	if x0 > x1 { x0, x1 = x1, x0; y0, y1 = y1, y0 }

	delta_x := f64(x1) - f64(x0)
	delta_y := f64(y1) - f64(y0)
	gradient := f64(1.0)
	if delta_x != 0.0 do gradient = delta_y / delta_x
	first_x_end := math.floor_f64(f64(x0) + 0.5)
	first_y_end := f64(y0) + gradient*(first_x_end-f64(x0))
	first_x_pixel, first_y_pixel := i64(first_x_end), i64(math.floor_f64(first_y_end))
	first_gap := reverse_fraction_part(f64(x0) + 0.5)
	second_x_end := math.floor_f64(f64(x1) + 0.5)
	second_y_end := f64(y1) + gradient*(second_x_end-f64(x1))
	second_x_pixel, second_y_pixel := i64(second_x_end), i64(math.floor_f64(second_y_end))
	second_gap := fraction_part(f64(x1) + 0.5)

	pixel_x: [MAX_PIXELS]i64
	pixel_y: [MAX_PIXELS]i64
	intensities: [MAX_PIXELS]f64
	pixel_count := 0
	add_endpoint(&pixel_x[0], &pixel_y[0], &intensities[0], &pixel_count,
		first_x_pixel, first_y_pixel, first_y_end, first_gap, steep)
	add_endpoint(&pixel_x[0], &pixel_y[0], &intensities[0], &pixel_count,
		second_x_pixel, second_y_pixel, second_y_end, second_gap, steep)

	intersection_y := first_y_end + gradient
	for x := first_x_pixel+1; x < second_x_pixel; x += 1 {
		y_floor := i64(math.floor_f64(intersection_y))
		fractional, complement := fraction_part(intersection_y), reverse_fraction_part(intersection_y)
		add_pixel(&pixel_x[0], &pixel_y[0], &intensities[0], &pixel_count, x, y_floor, complement, steep)
		add_pixel(&pixel_x[0], &pixel_y[0], &intensities[0], &pixel_count, x, y_floor+1, fractional, steep)
		intersection_y += gradient
	}

	required := pixel_count * 16
	if output == nil || output_capacity < c.size_t(required) do return -2
	for index := 0; index < pixel_count; index += 1 {
		offset := index*16
		write_i32_le(output, offset, pixel_x[index])
		write_i32_le(output, offset+4, pixel_y[index])
		write_f64_le(output, offset+8, intensities[index])
	}
	return i64(required)
}
