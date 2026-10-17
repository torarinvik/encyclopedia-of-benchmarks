package lu_pivot_decomposition

import "core:c"
import "core:math"

MAX_INPUT_LENGTH :: 18
MAX_DIMENSION :: 4

exact_integer :: proc(value: f64, minimum, maximum: i64) -> bool {
	if math.is_nan(value) || math.is_inf(value) || value < f64(minimum) || value > f64(maximum) do return false
	return f64(i64(value)) == value
}

magnitude :: proc(value: f64) -> f64 {
	if value < 0 do return -value
	return value
}

@(export)
lu_pivot_decomposition :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 1 || input_length > MAX_INPUT_LENGTH do return -1
	if !exact_integer(input[0], 1, MAX_DIMENSION) do return -1
	dimension := int(input[0])
	matrix_elements := dimension * dimension
	if int(input_length) != 1 + matrix_elements do return -1

	packed_lu: [16]f64
	for index := 0; index < matrix_elements; index += 1 {
		if !exact_integer(input[index+1], -8, 8) do return -1
		packed_lu[index] = input[index+1]
	}
	pivot: [5]i64
	for index := 0; index <= dimension; index += 1 { pivot[index] = i64(index) }

	for column := 0; column < dimension; column += 1 {
		max_value := f64(0)
		max_index := column
		for row := column; row < dimension; row += 1 {
			current_magnitude := magnitude(packed_lu[row*dimension+column])
			if current_magnitude > max_value {
				max_value = current_magnitude
				max_index = row
			}
		}
		if max_index != column {
			pivot[column], pivot[max_index] = pivot[max_index], pivot[column]
			for swap_column := 0; swap_column < dimension; swap_column += 1 {
				packed_lu[column*dimension+swap_column], packed_lu[max_index*dimension+swap_column] =
					packed_lu[max_index*dimension+swap_column], packed_lu[column*dimension+swap_column]
			}
			pivot[dimension] += 1
		}

		pivot_value := packed_lu[column*dimension+column]
		if pivot_value == 0 || math.is_nan(pivot_value) || math.is_inf(pivot_value) do return -1
		for row := column+1; row < dimension; row += 1 {
			packed_lu[row*dimension+column] /= pivot_value
			if math.is_nan(packed_lu[row*dimension+column]) || math.is_inf(packed_lu[row*dimension+column]) do return -1
			for trailing_column := column+1; trailing_column < dimension; trailing_column += 1 {
				packed_lu[row*dimension+trailing_column] -= packed_lu[row*dimension+column] * packed_lu[column*dimension+trailing_column]
				if math.is_nan(packed_lu[row*dimension+trailing_column]) || math.is_inf(packed_lu[row*dimension+trailing_column]) do return -1
			}
		}
	}

	output_length := matrix_elements + dimension + 1
	if output == nil || capacity < c.size_t(output_length) do return -2
	for index := 0; index < matrix_elements; index += 1 { output[index] = packed_lu[index] }
	for index := 0; index <= dimension; index += 1 { output[matrix_elements+index] = f64(pivot[index]) }
	return i64(output_length)
}
