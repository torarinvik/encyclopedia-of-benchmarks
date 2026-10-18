import math

const min_side = 3
const max_side = 16
const max_parseable_input_length = 258
const max_output_elements = 512
const max_output_bytes = 4096
const kernel_x = [-1, 0, 1, -2, 0, 2, -1, 0, 1]!
const kernel_y = [1, 2, 1, 0, 0, 0, -1, -2, -1]!

fn write_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'sobel_filter']
pub fn sobel_filter(input &i64, input_length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 2 || input_length > max_parseable_input_length { return -1 }
		if input[0] < min_side || input[0] > max_side { return -1 }
		side := int(input[0])
		pixel_count := side * side
		if int(input_length) != pixel_count + 1 { return -1 }

		mut image := [max_side * max_side]int{}
		for index in 0 .. pixel_count {
			if input[index + 1] < 0 || input[index + 1] > 255 { return -1 }
			image[index] = int(input[index + 1])
		}
		mut gradient_x := [max_side * max_side]int{}
		mut gradient_y := [max_side * max_side]int{}
		mut max_x := 0
		mut max_y := 0
		for y in 0 .. side {
			for x in 0 .. side {
				mut gx := 0
				mut gy := 0
				for ky in 0 .. 3 {
					mut sample_y := y + ky - 1
					if sample_y < 0 { sample_y = 0 }
					if sample_y >= side { sample_y = side - 1 }
					for kx in 0 .. 3 {
						mut sample_x := x + kx - 1
						if sample_x < 0 { sample_x = 0 }
						if sample_x >= side { sample_x = side - 1 }
						pixel := image[sample_y * side + sample_x]
						kernel_index := ky * 3 + kx
						gx += pixel * kernel_x[kernel_index]
						gy += pixel * kernel_y[kernel_index]
					}
				}
				gx = math.abs(gx)
				gy = math.abs(gy)
				index := y * side + x
				gradient_x[index] = gx
				gradient_y[index] = gy
				if gx > max_x { max_x = gx }
				if gy > max_y { max_y = gy }
			}
		}
		if max_x == 0 || max_y == 0 { return -1 }

		mut scaled_x := [max_side * max_side]f64{}
		mut scaled_y := [max_side * max_side]f64{}
		mut magnitude := [max_side * max_side]f64{}
		mut theta := [max_side * max_side]f64{}
		mut max_magnitude := 0.0
		for index in 0 .. pixel_count {
			scaled_x[index] = (f64(gradient_x[index]) * 255.0) / f64(max_x)
			scaled_y[index] = (f64(gradient_y[index]) * 255.0) / f64(max_y)
			magnitude[index] = math.sqrt((scaled_x[index] * scaled_x[index]) + (scaled_y[index] * scaled_y[index]))
			if magnitude[index] > max_magnitude { max_magnitude = magnitude[index] }
		}
		if max_magnitude == 0.0 { return -1 }
		for index in 0 .. pixel_count {
			normalized := (magnitude[index] * 255.0) / max_magnitude
			magnitude[index] = f64(u8(normalized))
			theta[index] = math.atan2(scaled_y[index], scaled_x[index])
		}

		output_elements := 2 * pixel_count
		output_bytes := output_elements * 8
		if output_elements > max_output_elements || output_bytes > max_output_bytes { return -1 }
		if output == nil || capacity < usize(output_bytes) { return -2 }
		for index in 0 .. pixel_count {
			write_f64_le(mut output, index * 8, magnitude[index])
			write_f64_le(mut output, (pixel_count + index) * 8, theta[index])
		}
		return i64(output_elements)
	}
}
