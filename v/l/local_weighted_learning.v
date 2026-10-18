module local_weighted_learning

import math

const max_n = 16
const max_d = 4
const max_parseable_input_length = 84
const pivot_floor = 0.000003814697265625

fn exact_integer(value f64, minimum int, maximum int) ?int {
	if !value.is_finite() || value < f64(minimum) || value > f64(maximum) || f64(int(value)) != value {
		return none
	}
	return int(value)
}

fn grid_value(value f64, minimum f64, maximum f64) bool {
	if !value.is_finite() || value < minimum || value > maximum { return false }
	scaled := value * 16.0
	return scaled.is_finite() && f64(int(scaled)) == scaled
}

@[export: 'local_weighted_learning']
pub fn local_weighted_learning(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 3 || input_length > max_parseable_input_length { return -1 }
		n_value := exact_integer(input[0], 2, max_n) or { return -1 }
		d_value := exact_integer(input[1], 1, max_d) or { return -1 }
		if d_value > n_value { return -1 }
		n := n_value
		d := d_value
		tau := input[2]
		if !grid_value(tau, 2.0, 8.0) { return -1 }
		expected_length := 3 + n*d + n
		if input_length != usize(expected_length) { return -1 }

		mut x_train := [max_n][max_d]f64{}
		mut y_train := [max_n]f64{}
		mut cursor := 3
		for row in 0 .. n {
			for feature in 0 .. d {
				value := input[cursor]
				cursor++
				if !grid_value(value, -4.0, 4.0) { return -1 }
				x_train[row][feature] = value
			}
		}
		for row in 0 .. n {
			value := input[cursor]
			cursor++
			if !grid_value(value, -8.0, 8.0) { return -1 }
			y_train[row] = value
		}

		mut staged := [max_n]f64{}
		for query in 0 .. n {
			mut weights := [max_n]f64{}
			for row in 0 .. n {
				mut distance_squared := f64(0.0)
				for feature in 0 .. d {
					delta := x_train[query][feature] - x_train[row][feature]
					squared_delta := delta * delta
					distance_squared = distance_squared + squared_delta
				}
				tau_squared := tau * tau
				denominator := (-2.0) * tau_squared
				exponent := distance_squared / denominator
				weights[row] = math.exp(exponent)
				if !weights[row].is_finite() || weights[row] <= 0.0 { return -1 }
			}

			mut normal := [max_d][max_d]f64{}
			mut rhs := [max_d]f64{}
			for row in 0 .. n {
				mut weighted_x := [max_d]f64{}
				for feature in 0 .. d { weighted_x[feature] = weights[row] * x_train[row][feature] }
				weighted_y := weights[row] * y_train[row]
				for p in 0 .. d {
					rhs_product := x_train[row][p] * weighted_y
					rhs[p] = rhs[p] + rhs_product
					for q in 0 .. d {
						product := x_train[row][p] * weighted_x[q]
						normal[p][q] = normal[p][q] + product
					}
				}
			}

			mut scale := f64(0.0)
			for index in 0 .. d {
				diagonal := math.abs(normal[index][index])
				if !diagonal.is_finite() { return -1 }
				if diagonal > scale { scale = diagonal }
			}
			if scale == 0.0 || !scale.is_finite() { return -1 }
			for pivot_column in 0 .. d {
				mut pivot_row := pivot_column
				mut pivot_magnitude := math.abs(normal[pivot_row][pivot_column])
				for candidate in pivot_column + 1 .. d {
					candidate_magnitude := math.abs(normal[candidate][pivot_column])
					if !candidate_magnitude.is_finite() { return -1 }
					if candidate_magnitude > pivot_magnitude {
						pivot_row = candidate
						pivot_magnitude = candidate_magnitude
					}
				}
				if !pivot_magnitude.is_finite() || pivot_magnitude <= pivot_floor * scale { return -1 }
				if pivot_row != pivot_column {
					for column in 0 .. d {
						temporary := normal[pivot_column][column]
						normal[pivot_column][column] = normal[pivot_row][column]
						normal[pivot_row][column] = temporary
					}
					temporary := rhs[pivot_column]
					rhs[pivot_column] = rhs[pivot_row]
					rhs[pivot_row] = temporary
				}
				pivot := normal[pivot_column][pivot_column]
				for row in pivot_column + 1 .. d {
					factor := normal[row][pivot_column] / pivot
					if !factor.is_finite() { return -1 }
					normal[row][pivot_column] = 0.0
					for column in pivot_column + 1 .. d {
						product := factor * normal[pivot_column][column]
						normal[row][column] = normal[row][column] - product
						if !normal[row][column].is_finite() { return -1 }
					}
					product := factor * rhs[pivot_column]
					rhs[row] = rhs[row] - product
					if !rhs[row].is_finite() { return -1 }
				}
			}

			mut coefficients := [max_d]f64{}
			mut reverse := d - 1
			for reverse >= 0 {
				mut residual := rhs[reverse]
				for column in reverse + 1 .. d {
					product := normal[reverse][column] * coefficients[column]
					residual = residual - product
				}
				diagonal := normal[reverse][reverse]
				if !residual.is_finite() || diagonal == 0.0 || !diagonal.is_finite() { return -1 }
				coefficients[reverse] = residual / diagonal
				if !coefficients[reverse].is_finite() { return -1 }
				reverse--
			}

			mut prediction := f64(0.0)
			for feature in 0 .. d {
				product := x_train[query][feature] * coefficients[feature]
				prediction = prediction + product
			}
			if !prediction.is_finite() { return -1 }
			staged[query] = prediction
		}

		if output == nil || output_capacity < usize(n) { return -2 }
		for index in 0 .. n { output[index] = staged[index] }
		return i64(n)
	}
}
