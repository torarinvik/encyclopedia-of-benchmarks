module berlekamp_welch_rs_decode

const field = 7
const max_n = 7
const max_variables = 8
const max_polynomial = 8
const max_input_length = 11

fn normalize(value int) int {
	remainder := value % field
	return if remainder < 0 { remainder + field } else { remainder }
}

fn trim_polynomial(polynomial &int, mut length &int) {
	unsafe {
		for length > 1 && polynomial[length - 1] == 0 { length-- }
	}
}

fn solve_homogeneous(mut matrix &int, row_count int, variable_count int, mut solution &int) bool {
	unsafe {
		inverse := [7]int{0, 1, 4, 5, 2, 3, 6}
		mut pivot_columns := [max_variables]int{}
		mut pivot_count := 0
		mut pivot_row := 0
		for column in 0 .. variable_count {
			mut found := -1
			for row in pivot_row .. row_count {
				if matrix[row * max_variables + column] != 0 { found = row; break }
			}
			if found < 0 { continue }
			for c in 0 .. variable_count {
				temp := matrix[pivot_row * max_variables + c]
				matrix[pivot_row * max_variables + c] = matrix[found * max_variables + c]
				matrix[found * max_variables + c] = temp
			}

			scale := inverse[matrix[pivot_row * max_variables + column]]
			for c in 0 .. variable_count {
				at := pivot_row * max_variables + c
				matrix[at] = normalize(matrix[at] * scale)
			}
			for row in 0 .. row_count {
				if row == pivot_row { continue }
				factor := matrix[row * max_variables + column]
				if factor == 0 { continue }
				for c in 0 .. variable_count {
					at := row * max_variables + c
					matrix[at] = normalize(matrix[at] - factor * matrix[pivot_row * max_variables + c])
				}
			}
			pivot_columns[pivot_count] = column
			pivot_count++
			pivot_row++
			if pivot_row == row_count { break }
		}

		mut free_column := -1
		for column in 0 .. variable_count {
			mut is_pivot := false
			for index in 0 .. pivot_count {
				if pivot_columns[index] == column { is_pivot = true; break }
			}
			if !is_pivot { free_column = column; break }
		}
		if free_column < 0 { return false }
		for column in 0 .. max_variables { solution[column] = 0 }
		solution[free_column] = 1
		for row in 0 .. pivot_count {
			solution[pivot_columns[row]] = normalize(-matrix[row * max_variables + free_column])
		}
		return true
	}
}

fn divide_polynomials(numerator &int, denominator &int, numerator_length int,
	denominator_length int, mut quotient &int, mut quotient_length &int) bool {
	unsafe {
		inverse := [7]int{0, 1, 4, 5, 2, 3, 6}
		mut remainder := [max_polynomial]int{}
		mut divisor := [max_polynomial]int{}
		for index in 0 .. max_polynomial {
			remainder[index] = numerator[index]
			divisor[index] = denominator[index]
			quotient[index] = 0
		}
		mut remainder_length := numerator_length
		mut divisor_length := denominator_length
		trim_polynomial(remainder[0], mut remainder_length)
		trim_polynomial(divisor[0], mut divisor_length)
		if divisor_length == 1 && divisor[0] == 0 { return false }
		quotient_length = 1
		if remainder_length >= divisor_length { quotient_length = remainder_length - divisor_length + 1 }
		inverse_lead := inverse[divisor[divisor_length - 1]]
		for !(remainder_length == 1 && remainder[0] == 0) && remainder_length >= divisor_length {
			shift := remainder_length - divisor_length
			factor := normalize(remainder[remainder_length - 1] * inverse_lead)
			quotient[shift] = factor
			for index in 0 .. divisor_length {
				remainder[shift + index] = normalize(remainder[shift + index] - factor * divisor[index])
			}
			trim_polynomial(remainder[0], mut remainder_length)
		}
		if remainder_length != 1 || remainder[0] != 0 { return false }
		trim_polynomial(quotient, mut quotient_length)
		return true
	}
}

fn decode(n int, k int, error_limit int, received &int) i64 {
	unsafe {
		q_count := k + error_limit
		e_count := error_limit + 1
		variable_count := q_count + e_count
		mut matrix := [max_n * max_variables]int{}
		for row in 0 .. n {
			x := row
			mut power := 1
			for degree in 0 .. q_count {
				matrix[row * max_variables + degree] = power
				power = power * x % field
			}
			power = 1
			for degree in 0 .. e_count {
				matrix[row * max_variables + q_count + degree] = normalize(-received[row] * power)
				power = power * x % field
			}
		}

		mut solution := [max_variables]int{}
		if !solve_homogeneous(mut matrix[0], n, variable_count, mut solution[0]) { return 0 }
		mut numerator := [max_polynomial]int{}
		mut locator := [max_polynomial]int{}
		for degree in 0 .. q_count { numerator[degree] = solution[degree] }
		for degree in 0 .. e_count { locator[degree] = solution[q_count + degree] }
		mut numerator_length := q_count
		mut locator_length := e_count
		trim_polynomial(numerator[0], mut numerator_length)
		trim_polynomial(locator[0], mut locator_length)

		mut coefficients := [max_polynomial]int{}
		mut coefficient_length := 0
		if !divide_polynomials(numerator[0], locator[0], numerator_length,
			locator_length, mut coefficients[0], mut coefficient_length) || coefficient_length > k {
			return 0
		}
		mut mismatches := 0
		for x in 0 .. n {
			mut value := 0
			for degree := k - 1; degree >= 0; degree-- {
				coefficient := if degree < coefficient_length { coefficients[degree] } else { 0 }
				value = (value * x + coefficient) % field
			}
			if value != received[x] { mismatches++ }
		}
		if mismatches > error_limit { return 0 }
		mut encoded := i64(1)
		mut place := i64(1)
		for degree in 0 .. k {
			if degree < coefficient_length { encoded += i64(coefficients[degree]) * place }
			place *= field
		}
		return encoded
	}
}

@[export: 'berlekamp_welch_rs_decode']
pub fn berlekamp_welch_rs_decode(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > usize(max_input_length) { return -1 }
		n_value, k_value, error_value := input[0], input[1], input[2]
		if n_value < 2 || n_value > max_n || k_value < 1 || k_value > 3 || k_value > n_value
			|| error_value < 0 || error_value > 2 { return -1 }
		n, k, error_limit := int(n_value), int(k_value), int(error_value)
		if 2 * error_limit > n - k || length != usize(3 + n) { return -1 }
		mut received := [max_n]int{}
		for index in 0 .. n {
			symbol := input[3 + index]
			if symbol < 0 || symbol >= field { return -1 }
			received[index] = int(symbol)
		}
		return decode(n, k, error_limit, received[0])
	}
}
