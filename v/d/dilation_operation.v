module dilation_operation

const max_input_length = 267

fn put_i32_le(output &u8, offset int, value i32) {
	bits := u32(value)
	unsafe {
		for byte in 0 .. 4 {
			output[offset + byte] = u8((bits >> u32(8 * byte)) & 255)
		}
	}
}

@[export: 'dilation_operation']
pub fn dilation_operation(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if input == nil || length < 12 || length > max_input_length { return -1 }
	unsafe {
		rows_value := input[0]
		columns_value := input[1]
		if rows_value < 1 || rows_value > 16 || columns_value < 1 || columns_value > 16 { return -1 }
		rows := int(rows_value)
		columns := int(columns_value)
		cells := rows * columns
		if length != usize(2 + cells + 9) { return -1 }
		for i in 0 .. cells + 9 {
			if input[2 + i] < 0 || input[2 + i] > 1 { return -1 }
		}
		if output == nil || output_capacity < cells * 4 { return -2 }
		for y in 0 .. rows {
			for x in 0 .. columns {
				mut sum := 0
				for ky in 0 .. 3 {
					for kx in 0 .. 3 {
						image_y := y + ky - 1
						image_x := x + kx - 1
						if image_y >= 0 && image_y < rows && image_x >= 0 && image_x < columns {
							sum += int(input[2 + image_y * columns + image_x] * input[2 + cells + ky * 3 + kx])
						}
					}
				}
				put_i32_le(output, (y * columns + x) * 4, i32(if sum > 0 { 1 } else { 0 }))
			}
		}
		return i64(cells)
	}
}
