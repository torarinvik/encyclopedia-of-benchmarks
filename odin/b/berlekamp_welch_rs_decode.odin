package berlekamp_welch_rs_decode

import "core:c"

FIELD :: 7
MAX_N :: 7
MAX_VARIABLES :: 8
MAX_POLYNOMIAL :: 8
MAX_INPUT_LENGTH :: 11

normalize :: proc(value: int) -> int {
	remainder := value % FIELD
	if remainder < 0 do return remainder + FIELD
	return remainder
}

trim_polynomial :: proc(polynomial: ^[MAX_POLYNOMIAL]int, length: ^int) {
	for length^ > 1 && polynomial[length^ - 1] == 0 { length^ -= 1 }
}

solve_homogeneous :: proc(matrix: ^[MAX_N][MAX_VARIABLES]int, row_count, variable_count: int,
		solution: ^[MAX_VARIABLES]int) -> bool {
	inverse := [7]int{0, 1, 4, 5, 2, 3, 6}
	var pivot_columns: [MAX_VARIABLES]int
	pivot_count, pivot_row := 0, 0
	for column := 0; column < variable_count; column += 1 {
		found := -1
		for row := pivot_row; row < row_count; row += 1 {
			if matrix[row][column] != 0 { found = row; break }
		}
		if found < 0 do continue
		temporary := matrix[pivot_row]
		matrix[pivot_row] = matrix[found]
		matrix[found] = temporary

		scale := inverse[matrix[pivot_row][column]]
		for c := 0; c < variable_count; c += 1 {
			matrix[pivot_row][c] = normalize(matrix[pivot_row][c] * scale)
		}
		for row := 0; row < row_count; row += 1 {
			if row == pivot_row do continue
			factor := matrix[row][column]
			if factor == 0 do continue
			for c := 0; c < variable_count; c += 1 {
				matrix[row][c] = normalize(matrix[row][c] - factor * matrix[pivot_row][c])
			}
		}

		pivot_columns[pivot_count] = column
		pivot_count += 1
		pivot_row += 1
		if pivot_row == row_count do break
	}

	free_column := -1
	for column := 0; column < variable_count; column += 1 {
		is_pivot := false
		for index := 0; index < pivot_count; index += 1 {
			if pivot_columns[index] == column { is_pivot = true; break }
		}
		if !is_pivot { free_column = column; break }
	}
	if free_column < 0 do return false
	for column := 0; column < MAX_VARIABLES; column += 1 do solution[column] = 0
	solution[free_column] = 1
	for row := 0; row < pivot_count; row += 1 {
		solution[pivot_columns[row]] = normalize(-matrix[row][free_column])
	}
	return true
}

divide_polynomials :: proc(numerator, denominator: ^[MAX_POLYNOMIAL]int,
		numerator_length, denominator_length: int, quotient: ^[MAX_POLYNOMIAL]int,
		quotient_length: ^int) -> bool {
	inverse := [7]int{0, 1, 4, 5, 2, 3, 6}
	remainder := numerator^
	divisor := denominator^
	remainder_length, divisor_length := numerator_length, denominator_length
	trim_polynomial(&remainder, &remainder_length)
	trim_polynomial(&divisor, &divisor_length)
	if divisor_length == 1 && divisor[0] == 0 do return false
	for index := 0; index < MAX_POLYNOMIAL; index += 1 do quotient[index] = 0
	quotient_length^ = 1
	if remainder_length >= divisor_length do quotient_length^ = remainder_length - divisor_length + 1
	inverse_lead := inverse[divisor[divisor_length - 1]]
	for !(remainder_length == 1 && remainder[0] == 0) && remainder_length >= divisor_length {
		shift := remainder_length - divisor_length
		factor := normalize(remainder[remainder_length - 1] * inverse_lead)
		quotient[shift] = factor
		for index := 0; index < divisor_length; index += 1 {
			remainder[shift + index] = normalize(remainder[shift + index] - factor * divisor[index])
		}
		trim_polynomial(&remainder, &remainder_length)
	}
	if remainder_length != 1 || remainder[0] != 0 do return false
	trim_polynomial(quotient, quotient_length)
	return true
}

decode :: proc(n, k, error_limit: int, received: ^[MAX_N]int) -> i64 {
	q_count := k + error_limit
	e_count := error_limit + 1
	variable_count := q_count + e_count
	var matrix: [MAX_N][MAX_VARIABLES]int
	for row := 0; row < n; row += 1 {
		x := row
		power := 1
		for degree := 0; degree < q_count; degree += 1 {
			matrix[row][degree] = power
			power = power * x % FIELD
		}
		power = 1
		for degree := 0; degree < e_count; degree += 1 {
			matrix[row][q_count + degree] = normalize(-received[row] * power)
			power = power * x % FIELD
		}
	}

	var solution: [MAX_VARIABLES]int
	if !solve_homogeneous(&matrix, n, variable_count, &solution) do return 0
	var numerator, locator: [MAX_POLYNOMIAL]int
	for degree := 0; degree < q_count; degree += 1 do numerator[degree] = solution[degree]
	for degree := 0; degree < e_count; degree += 1 do locator[degree] = solution[q_count + degree]
	numerator_length, locator_length := q_count, e_count
	trim_polynomial(&numerator, &numerator_length)
	trim_polynomial(&locator, &locator_length)

	var coefficients: [MAX_POLYNOMIAL]int
	coefficient_length := 0
	if !divide_polynomials(&numerator, &locator, numerator_length, locator_length,
			&coefficients, &coefficient_length) || coefficient_length > k do return 0

	mismatches := 0
	for x := 0; x < n; x += 1 {
		value := 0
		for degree := k - 1; degree >= 0; degree -= 1 {
			coefficient := 0
			if degree < coefficient_length do coefficient = coefficients[degree]
			value = (value * x + coefficient) % FIELD
		}
		if value != received[x] do mismatches += 1
	}
	if mismatches > error_limit do return 0

	encoded, place := i64(1), i64(1)
	for degree := 0; degree < k; degree += 1 {
		if degree < coefficient_length do encoded += i64(coefficients[degree]) * place
		place *= FIELD
	}
	return encoded
}

@(export)
berlekamp_welch_rs_decode :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT_LENGTH do return -1
	n_value, k_value, error_value := input[0], input[1], input[2]
	if n_value < 2 || n_value > MAX_N || k_value < 1 || k_value > 3 || k_value > n_value
		|| error_value < 0 || error_value > 2 do return -1
	n, k, error_limit := int(n_value), int(k_value), int(error_value)
	if 2 * error_limit > n - k || int(length) != 3 + n do return -1
	var received: [MAX_N]int
	for index := 0; index < n; index += 1 {
		symbol := input[3 + index]
		if symbol < 0 || symbol >= FIELD do return -1
		received[index] = int(symbol)
	}
	return decode(n, k, error_limit, &received)
}
