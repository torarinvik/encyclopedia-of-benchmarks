module gramian

import math

const max_input_length = 27

fn write_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

fn gram_matrix(values &i64, channels int, pixels int, part int, mut result [9]f64) {
	feature_count := channels * pixels
	for row in 0 .. channels {
		for column in 0 .. channels {
			mut dot := 0.0
			for pixel in 0 .. pixels {
				row_index := 3 + part * feature_count + row * pixels + pixel
				column_index := 3 + part * feature_count + column * pixels + pixel
				row_value := f64(unsafe { values[row_index] }) / 1000.0
				column_value := f64(unsafe { values[column_index] }) / 1000.0
				dot += row_value * column_value
			}
			result[row * channels + column] = dot / f64(feature_count)
		}
	}
}

@[export: 'gramian']
pub fn gramian(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { values == nil } || length < 3 || length > max_input_length { return -1 }
	unsafe {
		operation := values[0]
		raw_channels := values[1]
		raw_pixels := values[2]
		if (operation != 0 && operation != 1) || raw_channels < 1 || raw_channels > 3 ||
			raw_pixels < 1 || raw_pixels > 4 { return -1 }
		channels, pixels := int(raw_channels), int(raw_pixels)
		feature_count := channels * pixels
		map_count := if operation == 1 { 2 } else { 1 }
		if length != usize(3 + feature_count * map_count) { return -1 }
		for index in 3 .. int(length) {
			if values[index] < -1000 || values[index] > 1000 { return -1 }
		}
		output_count := if operation == 1 { 1 } else { channels * channels }
		required := output_count * 8
		if output == nil || output_capacity < usize(required) { return -2 }

		mut first := [9]f64{}
		gram_matrix(values, channels, pixels, 0, mut first)
		if operation == 0 {
			for index in 0 .. output_count {
				write_f64_le(mut output, index * 8, first[index])
			}
		} else {
			mut second := [9]f64{}
			gram_matrix(values, channels, pixels, 1, mut second)
			mut loss := 0.0
			for index in 0 .. channels * channels {
				difference := first[index] - second[index]
				loss += difference * difference
			}
			write_f64_le(mut output, 0, loss)
		}
		return i64(required)
	}
}
