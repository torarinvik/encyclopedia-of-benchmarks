package local_weighted_learning

import "core:c"
import "core:math"

MAX_N :: 16
MAX_D :: 4
MAX_PARSEABLE_INPUT_LENGTH :: 84
PIVOT_FLOOR :: 0.000003814697265625

finite_value :: proc "contextless" (value: f64) -> bool {
	return !math.is_nan(value) && !math.is_inf(value) && value == value
}

exact_integer :: proc "contextless" (value: f64, minimum, maximum: i64) -> (int, bool) {
	if !finite_value(value) || value < f64(minimum) || value > f64(maximum) do return 0, false
	integer := i64(value)
	if f64(integer) != value do return 0, false
	return int(integer), true
}

grid_value :: proc "contextless" (value, minimum, maximum: f64) -> bool {
	if !finite_value(value) || value < minimum || value > maximum do return false
	scaled := value * 16.0
	return finite_value(scaled) && f64(i64(scaled)) == scaled
}

@(export)
local_weighted_learning :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 3 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	n, n_ok := exact_integer(input[0], 2, MAX_N)
	d, d_ok := exact_integer(input[1], 1, MAX_D)
	if !n_ok || !d_ok || d > n do return -1
	tau := input[2]
	if !grid_value(tau, 2.0, 8.0) do return -1
	expected_length := 3 + n* d + n
	if int(input_length) != expected_length do return -1

	var x_train: [MAX_N][MAX_D]f64
	var y_train: [MAX_N]f64
	cursor := 3
	for row := 0; row < n; row += 1 {
		for feature := 0; feature < d; feature += 1 {
			value := input[cursor]
			cursor += 1
			if !grid_value(value, -4.0, 4.0) do return -1
			x_train[row][feature] = value
		}
	}
	for row := 0; row < n; row += 1 {
		value := input[cursor]
		cursor += 1
		if !grid_value(value, -8.0, 8.0) do return -1
		y_train[row] = value
	}

	var staged: [MAX_N]f64
	for query := 0; query < n; query += 1 {
		var weights: [MAX_N]f64
		for row := 0; row < n; row += 1 {
			distance_squared := f64(0.0)
			for feature := 0; feature < d; feature += 1 {
				delta := x_train[query][feature] - x_train[row][feature]
				squared_delta := delta * delta
				distance_squared = distance_squared + squared_delta
			}
			tau_squared := tau * tau
			denominator := (-2.0) * tau_squared
			exponent := distance_squared / denominator
			weights[row] = math.exp_f64(exponent)
			if !finite_value(weights[row]) || weights[row] <= 0.0 do return -1
		}

		var normal: [MAX_D][MAX_D]f64
		var rhs: [MAX_D]f64
		for row := 0; row < n; row += 1 {
			var weighted_x: [MAX_D]f64
			for feature := 0; feature < d; feature += 1 {
				weighted_x[feature] = weights[row] * x_train[row][feature]
			}
			weighted_y := weights[row] * y_train[row]
			for p := 0; p < d; p += 1 {
				rhs_product := x_train[row][p] * weighted_y
				rhs[p] = rhs[p] + rhs_product
				for q := 0; q < d; q += 1 {
					product := x_train[row][p] * weighted_x[q]
					normal[p][q] = normal[p][q] + product
				}
			}
		}

		scale := f64(0.0)
		for index := 0; index < d; index += 1 {
			diagonal := math.abs_f64(normal[index][index])
			if !finite_value(diagonal) do return -1
			if diagonal > scale { scale = diagonal }
		}
		if scale == 0.0 || !finite_value(scale) do return -1
		for pivot_column := 0; pivot_column < d; pivot_column += 1 {
			pivot_row := pivot_column
			pivot_magnitude := math.abs_f64(normal[pivot_row][pivot_column])
			for candidate := pivot_column + 1; candidate < d; candidate += 1 {
				candidate_magnitude := math.abs_f64(normal[candidate][pivot_column])
				if !finite_value(candidate_magnitude) do return -1
				if candidate_magnitude > pivot_magnitude {
					pivot_row = candidate
					pivot_magnitude = candidate_magnitude
				}
			}
			if !finite_value(pivot_magnitude) || pivot_magnitude <= PIVOT_FLOOR*scale do return -1
			if pivot_row != pivot_column {
				for column := 0; column < d; column += 1 {
					temporary := normal[pivot_column][column]
					normal[pivot_column][column] = normal[pivot_row][column]
					normal[pivot_row][column] = temporary
				}
				temporary := rhs[pivot_column]
				rhs[pivot_column] = rhs[pivot_row]
				rhs[pivot_row] = temporary
			}
			pivot := normal[pivot_column][pivot_column]
			for row := pivot_column + 1; row < d; row += 1 {
				factor := normal[row][pivot_column] / pivot
				if !finite_value(factor) do return -1
				normal[row][pivot_column] = 0.0
				for column := pivot_column + 1; column < d; column += 1 {
					product := factor * normal[pivot_column][column]
					normal[row][column] = normal[row][column] - product
					if !finite_value(normal[row][column]) do return -1
				}
				product := factor * rhs[pivot_column]
				rhs[row] = rhs[row] - product
				if !finite_value(rhs[row]) do return -1
			}
		}

		var coefficients: [MAX_D]f64
		for reverse := d - 1; reverse >= 0; reverse -= 1 {
			residual := rhs[reverse]
			for column := reverse + 1; column < d; column += 1 {
				product := normal[reverse][column] * coefficients[column]
				residual = residual - product
			}
			diagonal := normal[reverse][reverse]
			if !finite_value(residual) || diagonal == 0.0 || !finite_value(diagonal) do return -1
			coefficients[reverse] = residual / diagonal
			if !finite_value(coefficients[reverse]) do return -1
		}

		prediction := f64(0.0)
		for feature := 0; feature < d; feature += 1 {
			product := x_train[query][feature] * coefficients[feature]
			prediction = prediction + product
		}
		if !finite_value(prediction) do return -1
		staged[query] = prediction
	}

	if output == nil || output_capacity < c.size_t(n) do return -2
	for index := 0; index < n; index += 1 { output[index] = staged[index] }
	return i64(n)
}
