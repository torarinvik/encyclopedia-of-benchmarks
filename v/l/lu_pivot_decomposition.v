fn exact_integer(value f64, minimum i64, maximum i64) bool {
	if !value.is_finite() || value < f64(minimum) || value > f64(maximum) { return false }
	return f64(i64(value)) == value
}

fn magnitude(value f64) f64 {
	if value < 0 { return -value }
	return value
}

@[export: 'lu_pivot_decomposition']
pub fn lu_pivot_decomposition(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 1 || input_length > 18 { return -1 }
		if !exact_integer(input[0], 1, 4) { return -1 }
		dimension := int(input[0])
		matrix_elements := dimension * dimension
		if input_length != usize(1 + matrix_elements) { return -1 }

		mut packed_lu := [16]f64{}
		for index in 0 .. matrix_elements {
			value := input[index + 1]
			if !exact_integer(value, -8, 8) { return -1 }
			packed_lu[index] = value
		}
		mut pivot := [5]i64{}
		for index in 0 .. dimension + 1 { pivot[index] = i64(index) }

		for column in 0 .. dimension {
			mut max_value := f64(0)
			mut max_index := column
			for row in column .. dimension {
				current_magnitude := magnitude(packed_lu[row * dimension + column])
				if current_magnitude > max_value {
					max_value = current_magnitude
					max_index = row
				}
			}
			if max_index != column {
				temp_pivot := pivot[column]
				pivot[column] = pivot[max_index]
				pivot[max_index] = temp_pivot
				for swap_column in 0 .. dimension {
					temp_value := packed_lu[column * dimension + swap_column]
					packed_lu[column * dimension + swap_column] = packed_lu[max_index * dimension + swap_column]
					packed_lu[max_index * dimension + swap_column] = temp_value
				}
				pivot[dimension]++
			}

			pivot_value := packed_lu[column * dimension + column]
			if pivot_value == 0 || !pivot_value.is_finite() { return -1 }
			for row in column + 1 .. dimension {
				packed_lu[row * dimension + column] /= pivot_value
				if !packed_lu[row * dimension + column].is_finite() { return -1 }
				for trailing_column in column + 1 .. dimension {
					packed_lu[row * dimension + trailing_column] -=
						packed_lu[row * dimension + column] * packed_lu[column * dimension + trailing_column]
					if !packed_lu[row * dimension + trailing_column].is_finite() { return -1 }
				}
			}
		}

		output_length := matrix_elements + dimension + 1
		if output == nil || capacity < usize(output_length) { return -2 }
		for index in 0 .. matrix_elements { output[index] = packed_lu[index] }
		for index in 0 .. dimension + 1 { output[matrix_elements + index] = f64(pivot[index]) }
		return i64(output_length)
	}
}
