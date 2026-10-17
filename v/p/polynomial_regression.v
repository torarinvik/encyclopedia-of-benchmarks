import math

fn polynomial_regression_is_finite(value f64) bool {
	return value.is_finite()
}

fn polynomial_regression_exact_integer(value f64, minimum i64, maximum i64) bool {
	if !value.is_finite() || value < f64(minimum) || value > f64(maximum) { return false }
	return f64(i64(value)) == value
}

@[export: 'polynomial_regression']
pub fn polynomial_regression(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 3 || input_length > 18 { return -1 }
		if !polynomial_regression_exact_integer(input[0], 0, 3) ||
			!polynomial_regression_exact_integer(input[1], 1, 5) ||
			!polynomial_regression_exact_integer(input[2], 1, 4) { return -1 }
		degree := int(input[0])
		training_count := int(input[1])
		query_count := int(input[2])
		columns := degree + 1
		if training_count < columns || input_length != usize(3+2*training_count+query_count) { return -1 }

		mut x_train := [5]f64{}
		mut y_train := [5]f64{}
		mut x_query := [4]f64{}
		for i in 0 .. training_count {
			x := input[3+i]
			y := input[3+training_count+i]
			if !polynomial_regression_exact_integer(x, -2, 2) ||
				!polynomial_regression_exact_integer(y, -32, 32) { return -1 }
			x_train[i] = x
			y_train[i] = y
		}
		for i in 0 .. query_count {
			x := input[3+2*training_count+i]
			if !polynomial_regression_exact_integer(x, -2, 2) { return -1 }
			x_query[i] = x
		}
		for i in 0 .. training_count {
			for j in i+1 .. training_count {
				if x_train[i] == x_train[j] { return -1 }
			}
		}

		mut design := [5][4]f64{}
		for row in 0 .. training_count {
			mut power := f64(1)
			for column in 0 .. columns {
				design[row][column] = power
				power *= x_train[row]
			}
		}
		mut q_matrix := [5][4]f64{}
		mut r_matrix := [4][4]f64{}
		for column in 0 .. columns {
			mut vector := [5]f64{}
			for row in 0 .. training_count { vector[row] = design[row][column] }
			for previous in 0 .. column {
				mut dot := f64(0)
				for row in 0 .. training_count { dot += q_matrix[row][previous] * design[row][column] }
				r_matrix[previous][column] = dot
				for row in 0 .. training_count { vector[row] -= dot * q_matrix[row][previous] }
			}
			mut norm_squared := f64(0)
			for row in 0 .. training_count { norm_squared += vector[row] * vector[row] }
			if !norm_squared.is_finite() || norm_squared <= 0 { return -1 }
			norm := math.sqrt(norm_squared)
			if !norm.is_finite() || norm <= 0 { return -1 }
			r_matrix[column][column] = norm
			for row in 0 .. training_count { q_matrix[row][column] = vector[row] / norm }
		}

		mut projected := [4]f64{}
		for column in 0 .. columns {
			for row in 0 .. training_count { projected[column] += q_matrix[row][column] * y_train[row] }
		}
		mut coefficients := [4]f64{}
		for reverse in 0 .. columns {
			column := columns - reverse - 1
			mut value := projected[column]
			for next in column+1 .. columns { value -= r_matrix[column][next] * coefficients[next] }
			diagonal := r_matrix[column][column]
			if !diagonal.is_finite() || diagonal == 0 { return -1 }
			coefficients[column] = value / diagonal
			if !coefficients[column].is_finite() { return -1 }
		}

		output_length := columns + query_count
		mut staged := [8]f64{}
		for column in 0 .. columns { staged[column] = coefficients[column] }
		for query in 0 .. query_count {
			mut prediction := f64(0)
			mut power := f64(1)
			for column in 0 .. columns {
				prediction += power * coefficients[column]
				power *= x_query[query]
			}
			if !prediction.is_finite() { return -1 }
			staged[columns+query] = prediction
		}
		if output == nil || capacity < usize(output_length) { return -2 }
		for i in 0 .. output_length { output[i] = staged[i] }
		return i64(output_length)
	}
}
