module mean_threshold

const max_dimension = 32
const max_parseable_input_length = 1027

@[export: 'mean_threshold']
pub fn mean_threshold(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_parseable_input_length { return -1 }
		if input[0] < 1 || input[0] > max_dimension || input[1] < 1 || input[1] > max_dimension { return -1 }

		width := usize(input[0])
		height := usize(input[1])
		pixel_count := width * height
		if length != pixel_count + 2 { return -1 }

		mut sum := i64(0)
		for index in 0 .. int(pixel_count) {
			pixel := input[2 + index]
			if pixel < 0 || pixel > 255 { return -1 }
			sum += pixel
		}

		mean := sum / i64(pixel_count)
		if output_capacity < pixel_count || output == nil { return -2 }
		for index in 0 .. int(pixel_count) {
			output[index] = if input[2 + index] > mean { u8(255) } else { u8(0) }
		}
		return i64(pixel_count)
	}
}

