package linear_recurrence_matrix

import "core:c"
import "core:runtime"

MODULUS :: i64(1_000_000_007)
MAX_INPUT_LENGTH :: c.size_t(24)

multiply_matrix :: proc(left, right: [16]i64, dimension: int) -> [16]i64 {
	output: [16]i64
	for row := 0; row < dimension; row += 1 {
		for column := 0; column < dimension; column += 1 {
			value := i64(0)
			for inner := 0; inner < dimension; inner += 1 {
				value = (value + (left[row*dimension+inner] % MODULUS) *
					(right[inner*dimension+column] % MODULUS) % MODULUS) % MODULUS
			}
			output[row*dimension+column] = value
		}
	}
	return output
}

matrix_power :: proc(transition_matrix: [16]i64, dimension: int, initial_power: i64) -> [16]i64 {
	zero := true
	for index := 0; index < dimension*dimension; index += 1 {
		if transition_matrix[index] != 0 do zero = false
	}
	if zero {
		zero_matrix: [16]i64
		return zero_matrix
	}
	result: [16]i64
	base := transition_matrix
	for index := 0; index < dimension; index += 1 {
		result[index*dimension+index] = 1
	}
	power := initial_power
	for power > 0 {
		if (power & 1) != 0 do result = multiply_matrix(result, base, dimension)
		power /= 2
		base = multiply_matrix(base, base, dimension)
	}
	return result
}

@(export)
linear_recurrence_matrix :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	context = runtime.default_context()
	if input == nil || length < 3 || length > MAX_INPUT_LENGTH do return -1
	dimension_value := input[0]
	nth_term := input[1]
	constant_or_sum_included := input[2]
	if dimension_value < 1 || dimension_value > 4 || nth_term < 0 || nth_term > 1_000_000 ||
		(constant_or_sum_included != 0 && constant_or_sum_included != 1) {
		return -1
	}
	dimension := int(dimension_value)
	matrix_count := dimension * dimension
	if length != c.size_t(3+matrix_count+dimension) do return -1
	if constant_or_sum_included == 1 && nth_term < dimension_value-1 do return -1
	transition_matrix: [16]i64
	base_row: [4]i64
	for index := 0; index < matrix_count+dimension; index += 1 {
		value := input[3+index]
		if value < 0 || value >= MODULUS do return -1
		if index < matrix_count {
			transition_matrix[index] = value
		} else {
			base_row[index-matrix_count] = value
		}
	}
	if nth_term < dimension_value-constant_or_sum_included do return base_row[int(nth_term-constant_or_sum_included)]
	result := matrix_power(transition_matrix, dimension, nth_term-dimension_value+1+constant_or_sum_included)
	value := i64(0)
	for index := 0; index < dimension; index += 1 {
		value = (value + (base_row[index] % MODULUS) *
			(result[index*dimension+dimension-1] % MODULUS) % MODULUS) % MODULUS
	}
	return value
}
