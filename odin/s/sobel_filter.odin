package sobel_filter

import "core:c"
import "core:math"

MIN_SIDE :: 3
MAX_SIDE :: 16
MAX_PARSEABLE_INPUT_LENGTH :: 258
MAX_OUTPUT_ELEMENTS :: 512
MAX_OUTPUT_BYTES :: 4096
KERNEL_X :: [9]int{-1, 0, 1, -2, 0, 2, -1, 0, 1}
KERNEL_Y :: [9]int{1, 2, 1, 0, 0, 0, -1, -2, -1}

write_f64_le :: proc(output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> u64(byte * 8))
	}
}

@(export)
sobel_filter :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 2 || input_length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) do return -1
	if input[0] < MIN_SIDE || input[0] > MAX_SIDE do return -1
	side := int(input[0])
	pixel_count := side * side
	if int(input_length) != pixel_count + 1 do return -1

	image: [MAX_SIDE * MAX_SIDE]int
	for index := 0; index < pixel_count; index += 1 {
		if input[index + 1] < 0 || input[index + 1] > 255 do return -1
		image[index] = int(input[index + 1])
	}
	gradient_x: [MAX_SIDE * MAX_SIDE]int
	gradient_y: [MAX_SIDE * MAX_SIDE]int
	max_x, max_y := 0, 0
	for y := 0; y < side; y += 1 {
		for x := 0; x < side; x += 1 {
			gx, gy := 0, 0
			for ky := 0; ky < 3; ky += 1 {
				sample_y := y + ky - 1
				if sample_y < 0 do sample_y = 0
				if sample_y >= side do sample_y = side - 1
				for kx := 0; kx < 3; kx += 1 {
					sample_x := x + kx - 1
					if sample_x < 0 do sample_x = 0
					if sample_x >= side do sample_x = side - 1
					pixel := image[sample_y * side + sample_x]
					kernel_index := ky * 3 + kx
					gx += pixel * KERNEL_X[kernel_index]
					gy += pixel * KERNEL_Y[kernel_index]
				}
			}
			gx, gy = math.abs(gx), math.abs(gy)
			index := y * side + x
			gradient_x[index], gradient_y[index] = gx, gy
			if gx > max_x do max_x = gx
			if gy > max_y do max_y = gy
		}
	}
	if max_x == 0 || max_y == 0 do return -1

	scaled_x: [MAX_SIDE * MAX_SIDE]f64
	scaled_y: [MAX_SIDE * MAX_SIDE]f64
	magnitude: [MAX_SIDE * MAX_SIDE]f64
	theta: [MAX_SIDE * MAX_SIDE]f64
	max_magnitude := 0.0
	for index := 0; index < pixel_count; index += 1 {
		scaled_x[index] = (f64(gradient_x[index]) * 255.0) / f64(max_x)
		scaled_y[index] = (f64(gradient_y[index]) * 255.0) / f64(max_y)
		magnitude[index] = math.sqrt((scaled_x[index] * scaled_x[index]) + (scaled_y[index] * scaled_y[index]))
		if magnitude[index] > max_magnitude do max_magnitude = magnitude[index]
	}
	if max_magnitude == 0.0 do return -1
	for index := 0; index < pixel_count; index += 1 {
		normalized := (magnitude[index] * 255.0) / max_magnitude
		magnitude[index] = f64(u8(normalized))
		theta[index] = math.atan2(scaled_y[index], scaled_x[index])
	}

	output_elements := 2 * pixel_count
	output_bytes := output_elements * 8
	if output_elements > MAX_OUTPUT_ELEMENTS || output_bytes > MAX_OUTPUT_BYTES do return -1
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for index := 0; index < pixel_count; index += 1 {
		write_f64_le(output, index * 8, magnitude[index])
		write_f64_le(output, (pixel_count + index) * 8, theta[index])
	}
	return i64(output_elements)
}
