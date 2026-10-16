package image_convolution

import "core:c"

MAX_SIDE :: 16
MAX_KERNEL_SIDE :: 7

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> u64(byte * 8))
	}
}

@(export)
image_convolution :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 3 || length > 308 do return -1
	side_value := values[0]
	kernel_side_value := values[1]
	if side_value < 1 || side_value > MAX_SIDE || kernel_side_value < 1 ||
		kernel_side_value > MAX_KERNEL_SIDE || kernel_side_value % 2 == 0 {
		return -1
	}
	side := int(side_value)
	kernel_side := int(kernel_side_value)
	pixel_count := side * side
	kernel_count := kernel_side * kernel_side
	if length != c.size_t(2 + pixel_count + kernel_count) do return -1
	for index := 0; index < pixel_count; index += 1 {
		if values[2 + index] < 0 || values[2 + index] > 255 do return -1
	}
	for index := 0; index < kernel_count; index += 1 {
		weight := values[2 + pixel_count + index]
		if weight < -16 || weight > 16 do return -1
	}
	output_bytes := pixel_count * 8
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2

	radius := kernel_side / 2
	for row := 0; row < side; row += 1 {
		for column := 0; column < side; column += 1 {
			total: i64 = 0
			for kernel_row := 0; kernel_row < kernel_side; kernel_row += 1 {
				source_row := row + kernel_row - radius
				if source_row < 0 { source_row = 0 }
				if source_row >= side { source_row = side - 1 }
				for kernel_column := 0; kernel_column < kernel_side; kernel_column += 1 {
					source_column := column + kernel_column - radius
					if source_column < 0 { source_column = 0 }
					if source_column >= side { source_column = side - 1 }
					pixel := values[2 + source_row * side + source_column]
					weight := values[2 + pixel_count + kernel_row * kernel_side + kernel_column]
					total += pixel * weight
				}
			}
			store_i64_le(output, (row * side + column) * 8, total)
		}
	}
	return i64(output_bytes)
}
