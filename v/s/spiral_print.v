module spiral_print

const max_cells = 256
const max_input_length = 259

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'spiral_print']
pub fn spiral_print(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_length {
		return -1
	}
	unsafe {
		rows_value, columns_value := input[0], input[1]
		if rows_value < 1 || rows_value > 16 || columns_value < 2 || columns_value > 16 {
			return -1
		}
		rows, columns := int(rows_value), int(columns_value)
		cell_count := rows * columns
		if length != usize(2 + cell_count) {
			return -1
		}

		mut matrix := [max_cells]i64{}
		for index in 0 .. cell_count {
			value := input[2 + index]
			if value < -2147483648 || value > 2147483647 {
				return -1
			}
			matrix[index] = value
		}

		required_bytes := 8 * cell_count
		if unsafe { output == nil } || capacity < usize(required_bytes) {
			return -2
		}

		mut order := [max_cells]i64{}
		mut order_length := 0
		mut top, mut bottom := 0, rows - 1
		mut left, mut right := 0, columns - 1
		for top <= bottom && left <= right {
			for column in left .. right + 1 {
				order[order_length] = matrix[top * columns + column]
				order_length++
			}
			top++
			for row in top .. bottom + 1 {
				order[order_length] = matrix[row * columns + right]
				order_length++
			}
			right--

			if top <= bottom && left <= right {
				mut column := right
				for {
					order[order_length] = matrix[bottom * columns + column]
					order_length++
					if column == left {
						break
					}
					column--
				}
				bottom--
			}

			if top <= bottom && left <= right {
				mut row := bottom
				for {
					order[order_length] = matrix[row * columns + left]
					order_length++
					if row == top {
						break
					}
					row--
				}
				left++
			}
		}

		for index in 0 .. order_length {
			put_i64_le(mut output, index * 8, order[index])
		}
		return i64(required_bytes)
	}
}
