package sherman_morrison

import "core:c"
import "core:math"

MAX_DIMENSION :: 4
MAX_INPUT_LENGTH :: 26
MAX_OUTPUT_ELEMENTS :: 16

@(export)
sherman_morrison :: proc "c" (input: [^]f64, input_length: c.size_t,
			output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 1 || input_length > MAX_INPUT_LENGTH do return -1
	dimension_value := input[0]
	if dimension_value != dimension_value || math.is_inf_f64(dimension_value) ||
		dimension_value < 1.0 || dimension_value > MAX_DIMENSION do return -1
	dimension := int(dimension_value)
	if f64(dimension) != dimension_value do return -1
	expected_length := 1 + dimension*dimension + 2*dimension
	if int(input_length) != expected_length do return -1

	coefficients: [MAX_OUTPUT_ELEMENTS + 2*MAX_DIMENSION]f64
	for index := 0; index < expected_length-1; index += 1 {
		value := input[1+index]
		if value != value || math.is_inf_f64(value) || value < -2.0 || value > 2.0 do return -1
		if f64(i64(value)) != value do return -1
		coefficients[index] = value
	}

	matrix_elements := dimension*dimension
	var matrix: [MAX_DIMENSION][MAX_DIMENSION]f64
	var u, v: [MAX_DIMENSION]f64
	for row := 0; row < dimension; row += 1 {
		for column := 0; column < dimension; column += 1 {
			matrix[row][column] = coefficients[row*dimension+column]
		}
	}
	for index := 0; index < dimension; index += 1 {
		u[index] = coefficients[matrix_elements+index]
		v[index] = coefficients[matrix_elements+dimension+index]
	}

	var right: [MAX_DIMENSION]f64
	for column := 0; column < dimension; column += 1 {
		for inner := 0; inner < dimension; inner += 1 {
			right[column] += v[inner] * matrix[inner][column]
		}
	}
	denominator: f64 = 0.0
	for inner := 0; inner < dimension; inner += 1 {
		denominator += right[inner] * u[inner]
	}
	denominator += 1.0

	var updated: [MAX_OUTPUT_ELEMENTS]f64
	if denominator != 0.0 {
		var left: [MAX_DIMENSION]f64
		for row := 0; row < dimension; row += 1 {
			for inner := 0; inner < dimension; inner += 1 {
				left[row] += matrix[row][inner] * u[inner]
			}
		}
		reciprocal := 1.0 / denominator
		for row := 0; row < dimension; row += 1 {
			for column := 0; column < dimension; column += 1 {
				outer_product := left[row] * right[column]
				scaled_product := outer_product * reciprocal
				updated[row*dimension+column] = matrix[row][column] - scaled_product
			}
		}
	}
	if output == nil do return -2
	if denominator == 0.0 do return 0
	if output_capacity < c.size_t(dimension*dimension) do return -2
	for index := 0; index < dimension*dimension; index += 1 { output[index] = updated[index] }
	return i64(dimension * dimension)
}
