package gaussian_filter

import "core:c"

gaussian_filter_weight :: proc(kernel_size, distance: i64) -> i64 {
	if kernel_size == 3 {
		if distance == 0 do return 159154943091895
		if distance == 1 do return 96532352630054
		return 58549831524319
	}
	if distance == 0 do return 198943678864869
	if distance == 1 do return 91083053297916
	if distance == 2 do return 41700860491808
	if distance == 4 do return 8740975213082
	if distance == 5 do return 4001910066968
	return 384051647741
}

@(export)
gaussian_filter :: proc "c" (values: [^]i64, length: c.size_t,
							 output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length < 3 do return -1
	height, width, kernel_size := values[0], values[1], values[2]
	if height < 3 || height > 12 || width < 3 || width > 12 do return -1
	if kernel_size != 3 && kernel_size != 5 do return -1
	if height < kernel_size || width < kernel_size do return -1
	if length != c.size_t(3 + height * width) do return -1
	for index := c.size_t(3); index < length; index += 1 {
		if values[index] < 0 || values[index] > 255 do return -1
	}

	output_height := int(height - kernel_size + 1)
	output_width := int(width - kernel_size + 1)
	output_count := output_height * output_width
	if capacity < c.size_t(output_count) || output == nil do return -2
	center := kernel_size / 2
	for row := 0; row < output_height; row += 1 {
		for column := 0; column < output_width; column += 1 {
			total: i64 = 0
			for kernel_row: i64 = 0; kernel_row < kernel_size; kernel_row += 1 {
				dy := kernel_row - center
				for kernel_column: i64 = 0; kernel_column < kernel_size; kernel_column += 1 {
					dx := kernel_column - center
					pixel_index := 3 + (row + int(kernel_row)) * int(width) + column + int(kernel_column)
					total += values[pixel_index] * gaussian_filter_weight(kernel_size, dx * dx + dy * dy)
				}
			}
			output[row * output_width + column] = u8(total / 1000000000000000)
		}
	}
	return i64(output_count)
}
