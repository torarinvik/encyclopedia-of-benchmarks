module mean_threshold

const max_side_length = 32
const max_parseable_input_length = 1026

@[export: 'mean_threshold']
pub fn mean_threshold(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_input_length { return -1 }
		if input[0] < 1 || input[0] > max_side_length { return -1 }

		side := usize(input[0])
		pixel_count := side * side
		if length != pixel_count + 1 { return -1 }

		mut sum := i64(0)
		for index in 0 .. int(pixel_count) {
			pixel := input[1 + index]
			if pixel < 0 || pixel > 255 { return -1 }
			sum += pixel
		}

		mean := sum / i64(pixel_count)
		if output_capacity < pixel_count || output == nil { return -2 }
		for index in 0 .. int(pixel_count) {
			output[index] = if input[1 + index] > mean { u8(255) } else { u8(0) }
		}
		return i64(pixel_count)
	}
}

