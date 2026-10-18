fn exact_integer(value f64, minimum i64, maximum i64) bool {
	if !value.is_finite() || value < f64(minimum) || value > f64(maximum) { return false }
	return f64(i64(value)) == value
}

@[export: 'lu_elimination']
pub fn lu_elimination(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 1 || input_length > 22 { return -1 }
		if !exact_integer(input[0], 0, 4) { return -1 }
		dimension := int(input[0])
		matrix_elements := dimension * dimension
		if input_length != usize(1 + matrix_elements + dimension) { return -1 }

		mut matrix := [16]f64{}
		mut rhs := [4]f64{}
		for index in 0 .. matrix_elements {
			value := input[1 + index]
			if !exact_integer(value, -1, 1) { return -1 }
			matrix[index] = value
		}
		for index in 0 .. dimension {
			value := input[1 + matrix_elements + index]
			if !exact_integer(value, -8, 8) { return -1 }
			rhs[index] = value
		}

		mut lower := [16]f64{}
		mut upper := [16]f64{}
		for row in 0 .. dimension {
			for column in row .. dimension {
				mut sum := f64(0)
				for index in 0 .. row { sum += lower[row * dimension + index] * upper[index * dimension + column] }
				upper[row * dimension + column] = matrix[row * dimension + column] - sum
			}
			pivot := upper[row * dimension + row]
			if pivot == 0 || !pivot.is_finite() { return -1 }
			for column in row .. dimension {
				if row == column {
					lower[row * dimension + row] = 1
				} else {
					mut sum := f64(0)
					for index in 0 .. row { sum += lower[column * dimension + index] * upper[index * dimension + row] }
					lower[column * dimension + row] = (matrix[column * dimension + row] - sum) / pivot
					if !lower[column * dimension + row].is_finite() { return -1 }
				}
			}
		}

		mut transformed := [4]f64{}
		for row in 0 .. dimension {
			mut sum := f64(0)
			for column in 0 .. row { sum += transformed[column] * lower[row * dimension + column] }
			transformed[row] = (rhs[row] - sum) / lower[row * dimension + row]
			if !transformed[row].is_finite() { return -1 }
		}

		mut solution := [4]f64{}
		mut row := dimension - 1
		for dimension > 0 && row >= 0 {
			mut sum := f64(0)
			for column in row .. dimension { sum += solution[column] * upper[row * dimension + column] }
			pivot := upper[row * dimension + row]
			if pivot == 0 || !pivot.is_finite() { return -1 }
			solution[row] = (transformed[row] - sum) / pivot
			if !solution[row].is_finite() { return -1 }
			row--
		}

		if output == nil || capacity < usize(dimension) { return -2 }
		for index in 0 .. dimension { output[index] = solution[index] }
		return i64(dimension)
	}
}
