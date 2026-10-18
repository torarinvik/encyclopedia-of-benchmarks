package qr_decomposition

import "core:c"
import "core:math"

MAX_INPUT_LENGTH :: 18
MAX_DIMENSION :: 4

exact_integer :: proc(value: f64, minimum, maximum: i64) -> bool {
	if math.is_nan(value) || math.is_inf(value) || value < f64(minimum) || value > f64(maximum) do return false
	return f64(i64(value)) == value
}

@(export)
qr_decomposition :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 1 || input_length > MAX_INPUT_LENGTH do return -1
	if !exact_integer(input[0], 1, MAX_DIMENSION) do return -1
	dimension := int(input[0])
	matrix_elements := dimension * dimension
	if int(input_length) != 1 + matrix_elements do return -1

	matrix: [16]f64
	exact: [16]i64
	for index := 0; index < matrix_elements; index += 1 {
		value := input[index+1]
		if !exact_integer(value, -1, 1) do return -1
		matrix[index] = value
		exact[index] = i64(value)
	}

	previous_pivot := i64(1)
	for pivot_column := 0; pivot_column < dimension; pivot_column += 1 {
		pivot := exact[pivot_column*dimension+pivot_column]
		if pivot == 0 do return -1
		for row := pivot_column+1; row < dimension; row += 1 {
			for column := pivot_column+1; column < dimension; column += 1 {
				numerator := exact[row*dimension+column]*pivot - exact[row*dimension+pivot_column]*exact[pivot_column*dimension+column]
				exact[row*dimension+column] = numerator / previous_pivot
			}
			exact[row*dimension+pivot_column] = 0
		}
		previous_pivot = pivot
	}

	q, r: [16]f64
	for column := 0; column < dimension; column += 1 {
		residual: [4]f64
		for row := 0; row < dimension; row += 1 { residual[row] = matrix[row*dimension+column] }
		for previous := 0; previous < column; previous += 1 {
			projection := f64(0)
			for row := 0; row < dimension; row += 1 { projection += q[row*dimension+previous] * residual[row] }
			r[previous*dimension+column] = projection
			for row := 0; row < dimension; row += 1 { residual[row] -= projection * q[row*dimension+previous] }
		}
		squared := f64(0)
		for row := 0; row < dimension; row += 1 { squared += residual[row] * residual[row] }
		magnitude := math.sqrt_f64(squared)
		if magnitude == 0 || math.is_nan(magnitude) || math.is_inf(magnitude) do return -1
		r[column*dimension+column] = magnitude
		for row := 0; row < dimension; row += 1 { q[row*dimension+column] = residual[row] / magnitude }
	}

	reconstruction_squared, orthogonality_squared, lower_squared := f64(0), f64(0), f64(0)
	for row := 0; row < dimension; row += 1 {
		for column := 0; column < dimension; column += 1 {
			reconstructed, orthogonality := f64(0), f64(0)
			for inner := 0; inner < dimension; inner += 1 {
				reconstructed += q[row*dimension+inner] * r[inner*dimension+column]
				orthogonality += q[inner*dimension+row] * q[inner*dimension+column]
			}
			reconstruction_error := matrix[row*dimension+column] - reconstructed
			reconstruction_squared += reconstruction_error * reconstruction_error
			if row == column { orthogonality -= 1 }
			orthogonality_squared += orthogonality * orthogonality
			if row > column { lower_squared += r[row*dimension+column] * r[row*dimension+column] }
		}
	}
	result := [3]f64{math.sqrt_f64(reconstruction_squared), math.sqrt_f64(orthogonality_squared), math.sqrt_f64(lower_squared)}
	for value in result {
		if math.is_nan(value) || math.is_inf(value) do return -1
	}
	if output == nil || capacity < 3 do return -2
	for index := 0; index < 3; index += 1 { output[index] = result[index] }
	return 3
}
