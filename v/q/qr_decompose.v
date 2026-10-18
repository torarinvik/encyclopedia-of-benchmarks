import math

fn exact_integer(value f64, minimum i64, maximum i64) bool {
	if !value.is_finite() || value < f64(minimum) || value > f64(maximum) { return false }
	return f64(i64(value)) == value
}

@[export: 'qr_decompose']
pub fn qr_decompose(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 1 || input_length > 18 { return -1 }
		if !exact_integer(input[0], 1, 4) { return -1 }
		dimension := int(input[0])
		matrix_elements := dimension * dimension
		if input_length != usize(1 + matrix_elements) { return -1 }

		mut matrix := [16]f64{}
		mut bareiss := [16]i64{}
		for index in 0 .. matrix_elements {
			value := input[index + 1]
			if !exact_integer(value, -4, 4) { return -1 }
			matrix[index] = value
			bareiss[index] = i64(value)
		}

		mut sign := i64(1)
		mut previous_pivot := i64(1)
		for pivot_column in 0 .. dimension - 1 {
			mut pivot_row := pivot_column
			for pivot_row < dimension && bareiss[pivot_row * dimension + pivot_column] == 0 { pivot_row++ }
			if pivot_row == dimension { return -1 }
			if pivot_row != pivot_column {
				for swap_column in 0 .. dimension {
					saved := bareiss[pivot_column * dimension + swap_column]
					bareiss[pivot_column * dimension + swap_column] = bareiss[pivot_row * dimension + swap_column]
					bareiss[pivot_row * dimension + swap_column] = saved
				}
				sign = -sign
			}
			pivot_value := bareiss[pivot_column * dimension + pivot_column]
			for row in pivot_column + 1 .. dimension {
				for column in pivot_column + 1 .. dimension {
					numerator := bareiss[row * dimension + column] * pivot_value -
						bareiss[row * dimension + pivot_column] * bareiss[pivot_column * dimension + column]
					bareiss[row * dimension + column] = numerator / previous_pivot
				}
				bareiss[row * dimension + pivot_column] = 0
			}
			previous_pivot = pivot_value
		}
		if sign * bareiss[(dimension - 1) * dimension + dimension - 1] == 0 { return -1 }

		mut q := [16]f64{}
		mut r := [16]f64{}
		for column in 0 .. dimension {
			mut source := [4]f64{}
			mut residual := [4]f64{}
			for row in 0 .. dimension {
				source[row] = matrix[row * dimension + column]
				residual[row] = source[row]
			}
			for previous in 0 .. column {
				mut numerator := f64(0)
				mut denominator := f64(0)
				for row in 0 .. dimension {
					numerator += source[row] * q[row * dimension + previous]
					denominator += q[row * dimension + previous] * q[row * dimension + previous]
				}
				if denominator == 0 || !denominator.is_finite() { return -1 }
				scalar := numerator / denominator
				for row in 0 .. dimension { residual[row] -= scalar * q[row * dimension + previous] }
			}
			mut residual_squared := f64(0)
			for row in 0 .. dimension { residual_squared += residual[row] * residual[row] }
			magnitude := math.sqrt(residual_squared)
			if magnitude == 0 || !magnitude.is_finite() { return -1 }
			for row in 0 .. dimension { q[row * dimension + column] = residual[row] / magnitude }
			for target_column in column .. dimension {
				mut dot := f64(0)
				for row in 0 .. dimension { dot += q[row * dimension + column] * matrix[row * dimension + target_column] }
				r[column * dimension + target_column] = dot
			}
		}

		for index in 0 .. matrix_elements {
			if !q[index].is_finite() || !r[index].is_finite() { return -1 }
		}
		output_length := 2 * matrix_elements
		if output == nil || capacity < usize(output_length) { return -2 }
		for index in 0 .. matrix_elements {
			output[index] = q[index]
			output[matrix_elements + index] = r[index]
		}
		return i64(output_length)
	}
}
