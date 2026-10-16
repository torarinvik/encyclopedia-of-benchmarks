fn gaussian_filter_weight(kernel_size i64, distance i64) i64 {
	if kernel_size == 3 {
		if distance == 0 { return 159154943091895 }
		if distance == 1 { return 96532352630054 }
		return 58549831524319
	}
	if distance == 0 { return 198943678864869 }
	if distance == 1 { return 91083053297916 }
	if distance == 2 { return 41700860491808 }
	if distance == 4 { return 8740975213082 }
	if distance == 5 { return 4001910066968 }
	return 384051647741
}

@[export: 'gaussian_filter']
pub fn gaussian_filter(values &i64, length usize, output &u8, capacity usize) i64 {
	if length < 3 { return -1 }
	height := unsafe { values[0] }
	width := unsafe { values[1] }
	kernel_size := unsafe { values[2] }
	if height < 3 || height > 12 || width < 3 || width > 12 { return -1 }
	if kernel_size != 3 && kernel_size != 5 { return -1 }
	if height < kernel_size || width < kernel_size { return -1 }
	if length != usize(3 + height * width) { return -1 }
	for index := 3; index < length; index++ {
		pixel := unsafe { values[index] }
		if pixel < 0 || pixel > 255 { return -1 }
	}
	output_height := int(height - kernel_size + 1)
	output_width := int(width - kernel_size + 1)
	output_count := output_height * output_width
	if capacity < usize(output_count) || isnil(output) { return -2 }
	center := kernel_size / 2
	for row := 0; row < output_height; row++ {
		for column := 0; column < output_width; column++ {
			total := i64(0)
			for kernel_row := i64(0); kernel_row < kernel_size; kernel_row++ {
				dy := kernel_row - center
				for kernel_column := i64(0); kernel_column < kernel_size; kernel_column++ {
					dx := kernel_column - center
					pixel_index := 3 + (row + int(kernel_row)) * int(width) + column + int(kernel_column)
					pixel := unsafe { values[pixel_index] }
					total += pixel * gaussian_filter_weight(kernel_size, dx * dx + dy * dy)
				}
			}
			unsafe { output[row * output_width + column] = u8(total / 1000000000000000) }
		}
	}
	return i64(output_count)
}
