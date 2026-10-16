module flip_augmentation

const coordinate_scale = 1000000

fn store_i32_le(mut output &u8, position int, value i32) {
	bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[position + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

// Flip grayscale pixels and reflect normalized bounding-box centers.
@[export: 'flip_augmentation']
pub fn flip_augmentation(values &i64, length usize, mut output &u8,
		output_capacity usize) i64 {
	if length < 4 || length > 340 { return -1 }
	if unsafe { values == nil } { return -1 }
	width_value := unsafe { values[0] }
	height_value := unsafe { values[1] }
	flip_type_value := unsafe { values[2] }
	box_count_value := unsafe { values[3] }
	if width_value < 1 || width_value > 16 || height_value < 1 || height_value > 16 { return -1 }
	if (flip_type_value != 0 && flip_type_value != 1) || box_count_value < 0 || box_count_value > 16 { return -1 }
	width, height, flip_type, box_count := int(width_value), int(height_value), int(flip_type_value), int(box_count_value)
	pixel_count := width * height
	if int(length) != 4 + pixel_count + 5 * box_count { return -1 }
	for index in 0 .. pixel_count {
		pixel := unsafe { values[4 + index] }
		if pixel < 0 || pixel > 255 { return -1 }
	}
	for box in 0 .. box_count {
		base := 4 + pixel_count + 5 * box
		class_id := unsafe { values[base] }
		if class_id < 0 || class_id > 2147483647 { return -1 }
		for field in 1 .. 5 {
			coordinate := unsafe { values[base + field] }
			if coordinate < 0 || coordinate > coordinate_scale { return -1 }
		}
	}
	output_bytes := pixel_count + 20 * box_count
	if output_capacity < usize(output_bytes) || unsafe { output == nil } { return -2 }

	unsafe {
		for row in 0 .. height {
			for column in 0 .. width {
				source_row := if flip_type == 0 { height - 1 - row } else { row }
				source_column := if flip_type == 1 { width - 1 - column } else { column }
				output[row * width + column] = u8(values[4 + source_row * width + source_column])
			}
		}
		for box in 0 .. box_count {
			base := 4 + pixel_count + 5 * box
			output_base := pixel_count + 20 * box
			for field in 0 .. 5 {
				mut value := values[base + field]
				if flip_type == 1 && field == 1 { value = coordinate_scale - value }
				if flip_type == 0 && field == 2 { value = coordinate_scale - value }
				store_i32_le(mut output, output_base + 4 * field, i32(value))
			}
		}
	}
	return i64(output_bytes)
}
