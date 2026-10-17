package polynomial_regression

import "core:c"
import "core:math"

MAX_INPUT_LENGTH :: 18

is_finite :: proc(value: f64) -> bool {
	return !math.is_nan(value) && !math.is_inf(value)
}

exact_integer :: proc(value: f64, minimum, maximum: i64) -> bool {
	if !is_finite(value) || value < f64(minimum) || value > f64(maximum) do return false
	return f64(i64(value)) == value
}

@(export)
polynomial_regression :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 3 || input_length > MAX_INPUT_LENGTH do return -1
	if !exact_integer(input[0], 0, 3) || !exact_integer(input[1], 1, 5) ||
		!exact_integer(input[2], 1, 4) do return -1
	degree := int(input[0])
	training_count := int(input[1])
	query_count := int(input[2])
	columns := degree + 1
	if training_count < columns || int(input_length) != 3+2*training_count+query_count do return -1

	x_train, y_train: [5]f64
	x_query: [4]f64
	for i := 0; i < training_count; i += 1 {
		x := input[3+i]
		y := input[3+training_count+i]
		if !exact_integer(x, -2, 2) || !exact_integer(y, -32, 32) do return -1
		x_train[i] = x
		y_train[i] = y
	}
	for i := 0; i < query_count; i += 1 {
		x := input[3+2*training_count+i]
		if !exact_integer(x, -2, 2) do return -1
		x_query[i] = x
	}
	for i := 0; i < training_count; i += 1 {
		for j := i+1; j < training_count; j += 1 {
			if x_train[i] == x_train[j] do return -1
		}
	}

	design: [5][4]f64
	for row := 0; row < training_count; row += 1 {
		power := f64(1)
		for column := 0; column < columns; column += 1 {
			design[row][column] = power
			power *= x_train[row]
		}
	}
	q_matrix: [5][4]f64
	r_matrix: [4][4]f64
	for column := 0; column < columns; column += 1 {
		vector: [5]f64
		for row := 0; row < training_count; row += 1 { vector[row] = design[row][column] }
		for previous := 0; previous < column; previous += 1 {
			dot := f64(0)
			for row := 0; row < training_count; row += 1 { dot += q_matrix[row][previous] * design[row][column] }
			r_matrix[previous][column] = dot
			for row := 0; row < training_count; row += 1 { vector[row] -= dot * q_matrix[row][previous] }
		}
		norm_squared := f64(0)
		for row := 0; row < training_count; row += 1 { norm_squared += vector[row] * vector[row] }
		if !is_finite(norm_squared) || norm_squared <= 0 do return -1
		norm := math.sqrt(norm_squared)
		if !is_finite(norm) || norm <= 0 do return -1
		r_matrix[column][column] = norm
		for row := 0; row < training_count; row += 1 { q_matrix[row][column] = vector[row] / norm }
	}

	projected: [4]f64
	for column := 0; column < columns; column += 1 {
		for row := 0; row < training_count; row += 1 { projected[column] += q_matrix[row][column] * y_train[row] }
	}
	coefficients: [4]f64
	for reverse := 0; reverse < columns; reverse += 1 {
		column := columns-reverse-1
		value := projected[column]
		for next := column+1; next < columns; next += 1 { value -= r_matrix[column][next] * coefficients[next] }
		diagonal := r_matrix[column][column]
		if !is_finite(diagonal) || diagonal == 0 do return -1
		coefficients[column] = value / diagonal
		if !is_finite(coefficients[column]) do return -1
	}

	output_length := columns + query_count
	staged: [8]f64
	for column := 0; column < columns; column += 1 { staged[column] = coefficients[column] }
	for query := 0; query < query_count; query += 1 {
		prediction := f64(0)
		power := f64(1)
		for column := 0; column < columns; column += 1 {
			prediction += power * coefficients[column]
			power *= x_query[query]
		}
		if !is_finite(prediction) do return -1
		staged[columns+query] = prediction
	}
	if output == nil || capacity < c.size_t(output_length) do return -2
	for i := 0; i < output_length; i += 1 { output[i] = staged[i] }
	return i64(output_length)
}
