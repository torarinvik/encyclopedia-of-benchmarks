package qr_decompose

import "core:c"
import "core:math"

MAX_INPUT_LENGTH :: 18
MAX_DIMENSION :: 4

exact_integer :: proc(value: f64, minimum, maximum: i64) -> bool {
	if math.is_nan(value) || math.is_inf(value) || value < f64(minimum) || value > f64(maximum) do return false
	return f64(i64(value)) == value
}

@(export)
qr_decompose :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 1 || input_length > MAX_INPUT_LENGTH do return -1
	if !exact_integer(input[0], 1, MAX_DIMENSION) do return -1
	dimension := int(input[0])
	matrix_elements := dimension * dimension
	if int(input_length) != 1 + matrix_elements do return -1

	matrix: [16]f64
	bareiss: [16]i64
	for index := 0; index < matrix_elements; index += 1 {
		value := input[index+1]
		if !exact_integer(value, -4, 4) do return -1
		matrix[index] = value
		bareiss[index] = i64(value)
	}

	sign := i64(1)
	previous_pivot := i64(1)
	for pivot_column := 0; pivot_column < dimension-1; pivot_column += 1 {
		pivot_row := pivot_column
		for pivot_row < dimension && bareiss[pivot_row*dimension+pivot_column] == 0 { pivot_row += 1 }
		if pivot_row == dimension do return -1
		if pivot_row != pivot_column {
			for swap_column := 0; swap_column < dimension; swap_column += 1 {
				bareiss[pivot_column*dimension+swap_column], bareiss[pivot_row*dimension+swap_column] =
					bareiss[pivot_row*dimension+swap_column], bareiss[pivot_column*dimension+swap_column]
			}
			sign = -sign
		}
		pivot_value := bareiss[pivot_column*dimension+pivot_column]
		for row := pivot_column+1; row < dimension; row += 1 {
			for column := pivot_column+1; column < dimension; column += 1 {
				numerator := bareiss[row*dimension+column]*pivot_value - bareiss[row*dimension+pivot_column]*bareiss[pivot_column*dimension+column]
				bareiss[row*dimension+column] = numerator / previous_pivot
			}
			bareiss[row*dimension+pivot_column] = 0
		}
		previous_pivot = pivot_value
	}
	if sign*bareiss[(dimension-1)*dimension+dimension-1] == 0 do return -1

	q, r: [16]f64
	for column := 0; column < dimension; column += 1 {
		source, residual: [4]f64
		for row := 0; row < dimension; row += 1 {
			source[row] = matrix[row*dimension+column]
			residual[row] = source[row]
		}
		for previous := 0; previous < column; previous += 1 {
			numerator, denominator := f64(0), f64(0)
			for row := 0; row < dimension; row += 1 {
				numerator += source[row] * q[row*dimension+previous]
				denominator += q[row*dimension+previous] * q[row*dimension+previous]
			}
			if denominator == 0 || math.is_nan(denominator) || math.is_inf(denominator) do return -1
			scalar := numerator / denominator
			for row := 0; row < dimension; row += 1 { residual[row] -= scalar * q[row*dimension+previous] }
		}
		residual_squared := f64(0)
		for row := 0; row < dimension; row += 1 { residual_squared += residual[row] * residual[row] }
		magnitude := math.sqrt_f64(residual_squared)
		if magnitude == 0 || math.is_nan(magnitude) || math.is_inf(magnitude) do return -1
		for row := 0; row < dimension; row += 1 { q[row*dimension+column] = residual[row] / magnitude }
		for target_column := column; target_column < dimension; target_column += 1 {
			dot := f64(0)
			for row := 0; row < dimension; row += 1 { dot += q[row*dimension+column] * matrix[row*dimension+target_column] }
			r[column*dimension+target_column] = dot
		}
	}

	for index := 0; index < matrix_elements; index += 1 {
		if math.is_nan(q[index]) || math.is_inf(q[index]) || math.is_nan(r[index]) || math.is_inf(r[index]) do return -1
	}
	output_length := 2 * matrix_elements
	if output == nil || capacity < c.size_t(output_length) do return -2
	for index := 0; index < matrix_elements; index += 1 {
		output[index] = q[index]
		output[matrix_elements+index] = r[index]
	}
	return i64(output_length)
}
