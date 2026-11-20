// Integer-only Hough accumulator with four fixed quantized normals.
module hough_line_transform

const max_parseable_input_length = 67
const rho_count = 29
const output_bytes = 116

@[export: 'hough_line_transform']
pub fn hough_line_transform(input &i64, length usize, output &u8,
		output_capacity usize) i64 {
	if input == nil || length < 3 || length > max_parseable_input_length { return -1 }
	unsafe {
		height_value := input[0]
		width_value := input[1]
		if height_value < 1 || height_value > 8 || width_value < 1 || width_value > 8 {
			return -1
		}
		height := int(height_value)
		width := int(width_value)
		cells := height * width
		if length != usize(2 + cells) { return -1 }
		for index in 0 .. cells {
			if input[index + 2] != 0 && input[index + 2] != 1 { return -1 }
		}
		if output == nil || output_capacity < output_bytes { return -2 }

		mut accumulator := []u8{len: output_bytes, init: 0}
		for row in 0 .. height {
			for column in 0 .. width {
				if input[2 + row * width + column] == 0 { continue }
				x := i64(column)
				y := i64(row)
				rho := [4]i64{x, x + y, y, -x + y}
				for angle in 0 .. 4 {
					bin := angle * rho_count + int(rho[angle] + 14)
					accumulator[bin]++
				}
			}
		}
		for index in 0 .. output_bytes { output[index] = accumulator[index] }
		return i64(output_bytes)
	}
}
