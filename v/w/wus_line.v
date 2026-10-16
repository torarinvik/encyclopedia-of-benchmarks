module wus_line

import math

const coordinate_limit = i64(64)
const max_pixels = 258

fn fraction_part(value f64) f64 { return value - math.floor(value) }
fn reverse_fraction_part(value f64) f64 { return 1.0 - fraction_part(value) }

fn add_pixel(mut pixel_x []i64, mut pixel_y []i64, mut intensities []f64,
	mut count int, x i64, y i64, intensity f64, steep bool) {
	mut output_x := x
	mut output_y := y
	if steep { output_x = y; output_y = x }
	mut clamped := intensity
	if clamped < 0.0 { clamped = 0.0 }
	if clamped > 1.0 { clamped = 1.0 }
	pixel_x[count] = output_x
	pixel_y[count] = output_y
	intensities[count] = clamped
	count++
}

fn add_endpoint(mut pixel_x []i64, mut pixel_y []i64, mut intensities []f64,
	mut count int, x_pixel i64, y_pixel i64, y_end f64, x_gap f64, steep bool) {
	fractional_y := fraction_part(y_end)
	complement := reverse_fraction_part(y_end)
	add_pixel(mut pixel_x, mut pixel_y, mut intensities, mut count,
		x_pixel, y_pixel, complement * x_gap, steep)
	add_pixel(mut pixel_x, mut pixel_y, mut intensities, mut count,
		x_pixel, y_pixel + 1, fractional_y * x_gap, steep)
}

fn write_i32_le(mut output &u8, offset int, value i64) {
	bits := u32(i32(value))
	unsafe {
		for byte in 0 .. 4 { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

fn write_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	unsafe {
		for byte in 0 .. 8 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
	}
}

@[export: 'wus_line']
pub fn wus_line(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { values == nil } || length != 4 { return -1 }
	unsafe {
		for index in 0 .. 4 {
			if values[index] < -coordinate_limit || values[index] > coordinate_limit { return -1 }
		}
		mut x0 := values[0]
		mut y0 := values[1]
		mut x1 := values[2]
		mut y1 := values[3]
		mut dy := y1 - y0
		mut dx := x1 - x0
		if dy < 0 { dy = -dy }
		if dx < 0 { dx = -dx }
		steep := dy > dx
		if steep { x0, y0 = y0, x0; x1, y1 = y1, x1 }
		if x0 > x1 { x0, x1 = x1, x0; y0, y1 = y1, y0 }

		delta_x := f64(x1) - f64(x0)
		delta_y := f64(y1) - f64(y0)
		mut gradient := 1.0
		if delta_x != 0.0 { gradient = delta_y / delta_x }
		first_x_end := math.floor(f64(x0) + 0.5)
		first_y_end := f64(y0) + gradient * (first_x_end - f64(x0))
		first_x_pixel, first_y_pixel := i64(first_x_end), i64(math.floor(first_y_end))
		first_gap := reverse_fraction_part(f64(x0) + 0.5)
		second_x_end := math.floor(f64(x1) + 0.5)
		second_y_end := f64(y1) + gradient * (second_x_end - f64(x1))
		second_x_pixel, second_y_pixel := i64(second_x_end), i64(math.floor(second_y_end))
		second_gap := fraction_part(f64(x1) + 0.5)

		mut pixel_x := []i64{len: max_pixels, init: 0}
		mut pixel_y := []i64{len: max_pixels, init: 0}
		mut intensities := []f64{len: max_pixels, init: 0.0}
		mut pixel_count := 0
		add_endpoint(mut pixel_x, mut pixel_y, mut intensities, mut pixel_count,
			first_x_pixel, first_y_pixel, first_y_end, first_gap, steep)
		add_endpoint(mut pixel_x, mut pixel_y, mut intensities, mut pixel_count,
			second_x_pixel, second_y_pixel, second_y_end, second_gap, steep)

		mut intersection_y := first_y_end + gradient
		mut x := first_x_pixel + 1
		for x < second_x_pixel {
			y_floor := i64(math.floor(intersection_y))
			fractional, complement := fraction_part(intersection_y), reverse_fraction_part(intersection_y)
			add_pixel(mut pixel_x, mut pixel_y, mut intensities, mut pixel_count, x, y_floor, complement, steep)
			add_pixel(mut pixel_x, mut pixel_y, mut intensities, mut pixel_count, x, y_floor + 1, fractional, steep)
			intersection_y += gradient
			x++
		}

		required := pixel_count * 16
		if output == nil || output_capacity < usize(required) { return -2 }
		for index in 0 .. pixel_count {
			offset := index * 16
			write_i32_le(mut output, offset, pixel_x[index])
			write_i32_le(mut output, offset + 4, pixel_y[index])
			write_f64_le(mut output, offset + 8, intensities[index])
		}
		return i64(required)
	}
}
