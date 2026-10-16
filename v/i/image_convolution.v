module main

const max_side = 16
const max_kernel_side = 7

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'image_convolution']
pub fn image_convolution(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 308 { return -1 }
		side_value := input[0]
		kernel_side_value := input[1]
		if side_value < 1 || side_value > max_side || kernel_side_value < 1 ||
			kernel_side_value > max_kernel_side || kernel_side_value % 2 == 0 { return -1 }
		side := int(side_value)
		kernel_side := int(kernel_side_value)
		pixel_count := side * side
		kernel_count := kernel_side * kernel_side
		if int(length) != 2 + pixel_count + kernel_count { return -1 }
		for index in 0 .. pixel_count {
			if input[2 + index] < 0 || input[2 + index] > 255 { return -1 }
		}
		for index in 0 .. kernel_count {
			weight := input[2 + pixel_count + index]
			if weight < -16 || weight > 16 { return -1 }
		}
		output_bytes := pixel_count * 8
		if output == nil || int(output_capacity) < output_bytes { return -2 }

		radius := kernel_side / 2
		for row in 0 .. side {
			for column in 0 .. side {
				mut total := i64(0)
				for kernel_row in 0 .. kernel_side {
					mut source_row := row + kernel_row - radius
					if source_row < 0 { source_row = 0 }
					if source_row >= side { source_row = side - 1 }
					for kernel_column in 0 .. kernel_side {
						mut source_column := column + kernel_column - radius
						if source_column < 0 { source_column = 0 }
						if source_column >= side { source_column = side - 1 }
						pixel := input[2 + source_row * side + source_column]
						weight := input[2 + pixel_count + kernel_row * kernel_side + kernel_column]
						total += pixel * weight
					}
				}
				store_i64_le(mut output, (row * side + column) * 8, total)
			}
		}
		return i64(output_bytes)
	}
}
