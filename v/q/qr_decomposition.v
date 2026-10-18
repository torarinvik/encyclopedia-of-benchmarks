import math

fn exact_integer(value f64, minimum i64, maximum i64) bool {
	if !value.is_finite() || value < f64(minimum) || value > f64(maximum) { return false }
	return f64(i64(value)) == value
}

@[export: 'qr_decomposition']
pub fn qr_decomposition(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 1 || input_length > 18 { return -1 }
		if !exact_integer(input[0], 1, 4) { return -1 }
		dimension := int(input[0])
		matrix_elements := dimension * dimension
		if input_length != usize(1 + matrix_elements) { return -1 }

		mut matrix := [16]f64{}
		mut exact := [16]i64{}
		for index in 0 .. matrix_elements {
			value := input[index + 1]
			if !exact_integer(value, -1, 1) { return -1 }
			matrix[index] = value
			exact[index] = i64(value)
		}

		mut previous_pivot := i64(1)
		for pivot_column in 0 .. dimension {
			pivot := exact[pivot_column * dimension + pivot_column]
			if pivot == 0 { return -1 }
			for row in pivot_column + 1 .. dimension {
				for column in pivot_column + 1 .. dimension {
					numerator := exact[row * dimension + column] * pivot -
						exact[row * dimension + pivot_column] * exact[pivot_column * dimension + column]
					exact[row * dimension + column] = numerator / previous_pivot
				}
				exact[row * dimension + pivot_column] = 0
			}
			previous_pivot = pivot
		}

		mut q := [16]f64{}
		mut r := [16]f64{}
		for column in 0 .. dimension {
			mut residual := [4]f64{}
			for row in 0 .. dimension { residual[row] = matrix[row * dimension + column] }
			for previous in 0 .. column {
				mut projection := f64(0)
				for row in 0 .. dimension { projection += q[row * dimension + previous] * residual[row] }
				r[previous * dimension + column] = projection
				for row in 0 .. dimension { residual[row] -= projection * q[row * dimension + previous] }
			}
			mut squared := f64(0)
			for row in 0 .. dimension { squared += residual[row] * residual[row] }
			magnitude := math.sqrt(squared)
			if magnitude == 0 || !magnitude.is_finite() { return -1 }
			r[column * dimension + column] = magnitude
			for row in 0 .. dimension { q[row * dimension + column] = residual[row] / magnitude }
		}

		mut reconstruction_squared := f64(0)
		mut orthogonality_squared := f64(0)
		mut lower_squared := f64(0)
		for row in 0 .. dimension {
			for column in 0 .. dimension {
				mut reconstructed := f64(0)
				mut orthogonality := f64(0)
				for inner in 0 .. dimension {
					reconstructed += q[row * dimension + inner] * r[inner * dimension + column]
					orthogonality += q[inner * dimension + row] * q[inner * dimension + column]
				}
				reconstruction_error := matrix[row * dimension + column] - reconstructed
				reconstruction_squared += reconstruction_error * reconstruction_error
				if row == column { orthogonality -= 1 }
				orthogonality_squared += orthogonality * orthogonality
				if row > column { lower_squared += r[row * dimension + column] * r[row * dimension + column] }
			}
		}
		result := [3]f64{math.sqrt(reconstruction_squared), math.sqrt(orthogonality_squared), math.sqrt(lower_squared)}
		for value in result { if !value.is_finite() { return -1 } }
		if output == nil || capacity < 3 { return -2 }
		for index in 0 .. 3 { output[index] = result[index] }
		return 3
	}
}
