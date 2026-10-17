module max_pooling

import math

const max_n = 16
const max_input_words = 3 + max_n * max_n
const max_parseable_input_words = max_input_words + 1
const max_output_bytes = 8 * max_n * max_n

fn put_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'max_pooling']
pub fn max_pooling(input &i32, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > usize(max_parseable_input_words) { return -1 }
		n := input[0]
		size := input[1]
		stride := input[2]
		if n < 1 || n > max_n || size < 1 || size > n || stride < 1 || stride > max_n { return -1 }
		if int(length) != 3 + int(n * n) { return -1 }
		for i in 0 .. int(n * n) {
			if input[3 + i] < -1_000_000 || input[3 + i] > 1_000_000 { return -1 }
		}
		out_side := int((n - size) / stride + 1)
		bytes := out_side * out_side * 8
		if output == nil || capacity < usize(bytes) { return -2 }
		mut buffer := [max_output_bytes]u8{}
		mut position := 0
		for row in 0 .. out_side {
			for col in 0 .. out_side {
				start_row := row * int(stride)
				start_col := col * int(stride)
				mut maximum := input[3 + start_row * int(n) + start_col]
				for r in 0 .. int(size) {
					for c in 0 .. int(size) {
						value := input[3 + (start_row + r) * int(n) + start_col + c]
						if value > maximum { maximum = value }
					}
				}
				put_f64_le(mut buffer[0], position, f64(maximum))
				position += 8
			}
		}
		for i in 0 .. bytes { output[i] = buffer[i] }
		return i64(bytes)
	}
}
