package lu_elimination

import "core:c"
import "core:math"

MAX_INPUT_LENGTH :: 22
MAX_DIMENSION :: 4

exact_integer :: proc(value: f64, minimum, maximum: i64) -> bool {
	if math.is_nan(value) || math.is_inf(value) || value < f64(minimum) || value > f64(maximum) do return false
	return f64(i64(value)) == value
}

@(export)
lu_elimination :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 1 || input_length > MAX_INPUT_LENGTH do return -1
	if !exact_integer(input[0], 0, MAX_DIMENSION) do return -1
	dimension := int(input[0])
	matrix_elements := dimension * dimension
	if int(input_length) != 1 + matrix_elements + dimension do return -1

	matrix: [16]f64
	rhs: [4]f64
	for index := 0; index < matrix_elements; index += 1 {
		value := input[1+index]
		if !exact_integer(value, -1, 1) do return -1
		matrix[index] = value
	}
	for index := 0; index < dimension; index += 1 {
		value := input[1+matrix_elements+index]
		if !exact_integer(value, -8, 8) do return -1
		rhs[index] = value
	}

	lower, upper: [16]f64
	for row := 0; row < dimension; row += 1 {
		for column := row; column < dimension; column += 1 {
			sum := f64(0)
			for index := 0; index < row; index += 1 { sum += lower[row*dimension+index] * upper[index*dimension+column] }
			upper[row*dimension+column] = matrix[row*dimension+column] - sum
		}
		pivot := upper[row*dimension+row]
		if pivot == 0 || math.is_nan(pivot) || math.is_inf(pivot) do return -1
		for column := row; column < dimension; column += 1 {
			if row == column {
				lower[row*dimension+row] = 1
			} else {
				sum := f64(0)
				for index := 0; index < row; index += 1 { sum += lower[column*dimension+index] * upper[index*dimension+row] }
				lower[column*dimension+row] = (matrix[column*dimension+row] - sum) / pivot
				value := lower[column*dimension+row]
				if math.is_nan(value) || math.is_inf(value) do return -1
			}
		}
	}

	transformed: [4]f64
	for row := 0; row < dimension; row += 1 {
		sum := f64(0)
		for column := 0; column < row; column += 1 { sum += transformed[column] * lower[row*dimension+column] }
		transformed[row] = (rhs[row] - sum) / lower[row*dimension+row]
		if math.is_nan(transformed[row]) || math.is_inf(transformed[row]) do return -1
	}

	solution: [4]f64
	row := dimension - 1
	for dimension > 0 && row >= 0 {
		sum := f64(0)
		for column := row; column < dimension; column += 1 { sum += solution[column] * upper[row*dimension+column] }
		pivot := upper[row*dimension+row]
		if pivot == 0 || math.is_nan(pivot) || math.is_inf(pivot) do return -1
		solution[row] = (transformed[row] - sum) / pivot
		if math.is_nan(solution[row]) || math.is_inf(solution[row]) do return -1
		row -= 1
	}

	if output == nil || capacity < c.size_t(dimension) do return -2
	for index := 0; index < dimension; index += 1 { output[index] = solution[index] }
	return i64(dimension)
}
