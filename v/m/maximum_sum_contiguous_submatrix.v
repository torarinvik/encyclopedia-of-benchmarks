// Bounded row-compression and Kadane maximum-sum rectangle.
const max_parseable_input_length = 67
const output_bytes = 8

@[export: 'maximum_sum_contiguous_submatrix']
pub fn maximum_sum_contiguous_submatrix(input &i64, length usize, output &u8,
		output_capacity usize) i64 {
	if input == nil || length < 2 || length > max_parseable_input_length { return -1 }
	unsafe {
		rows_value := input[0]
		columns_value := input[1]
		if rows_value < 1 || rows_value > 8 || columns_value < 1 || columns_value > 8 {
			return -1
		}
		rows := int(rows_value)
		columns := int(columns_value)
		cells := rows * columns
		if length != usize(2 + cells) { return -1 }
		for index in 0 .. cells {
			if input[index + 2] < -1000 || input[index + 2] > 1000 { return -1 }
		}

		mut best := i64(-64001)
		mut column_sums := []i64{len: 8, init: 0}
		for top in 0 .. rows {
			for column in 0 .. columns { column_sums[column] = 0 }
			for bottom in top .. rows {
				row_offset := 2 + bottom * columns
				for column in 0 .. columns {
					column_sums[column] += input[row_offset + column]
				}
				mut current := column_sums[0]
				if current > best { best = current }
				for column in 1 .. columns {
					if current < 0 { current = column_sums[column] }
					else { current += column_sums[column] }
					if current > best { best = current }
				}
			}
		}
		if output == nil || output_capacity < output_bytes { return -2 }
		bits := u64(best)
		for byte in 0 .. 8 { output[byte] = u8((bits >> (byte * 8)) & 255) }
		return i64(output_bytes)
	}
}
