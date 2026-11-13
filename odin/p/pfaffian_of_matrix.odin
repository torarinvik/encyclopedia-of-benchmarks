package pfaffian_of_matrix

import "core:c"

MAX_N :: 8
MAX_DIMENSION :: 16
MAX_PARSEABLE :: 258
MODULUS :: i64(998244353)

normalize :: proc(value: i64) -> i64 {
	result := value % MODULUS
	if result < 0 do result += MODULUS
	return result
}

multiply :: proc(left, right: i64) -> i64 { return (left * right) % MODULUS }

power :: proc(base_value, exponent_value: i64) -> i64 {
	base, exponent := base_value, exponent_value
	result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 do result = multiply(result, base)
		base = multiply(base, base)
		exponent >>= 1
	}
	return result
}

@(export)
pfaffian_of_matrix :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 5 || length > c.size_t(MAX_PARSEABLE) do return -1
	if input[0] < 1 || input[0] > i64(MAX_N) do return -1
	dimension := int(2 * input[0])
	if length != c.size_t(1 + dimension * dimension) do return -1

	matrix := [MAX_DIMENSION * MAX_DIMENSION]i64{}
	for row := 0; row < dimension; row += 1 {
		for column := 0; column < dimension; column += 1 {
			value := input[1 + row * dimension + column]
			if value < 0 || value >= MODULUS do return -1
			matrix[row * MAX_DIMENSION + column] = value
		}
	}
	for row := 0; row < dimension; row += 1 {
		if matrix[row * MAX_DIMENSION + row] != 0 do return -1
		for column := row + 1; column < dimension; column += 1 {
			if (matrix[row * MAX_DIMENSION + column] + matrix[column * MAX_DIMENSION + row]) % MODULUS != 0 do return -1
		}
	}

	result := i64(1)
	for pivot_index := 0; pivot_index < dimension; pivot_index += 2 {
		partner := pivot_index + 1
		for partner < dimension && matrix[pivot_index * MAX_DIMENSION + partner] == 0 do partner += 1
		if partner == dimension do return 0
		if partner != pivot_index + 1 {
			swapped := pivot_index + 1
			for k := 0; k < dimension; k += 1 {
				temporary := matrix[swapped * MAX_DIMENSION + k]
				matrix[swapped * MAX_DIMENSION + k] = matrix[partner * MAX_DIMENSION + k]
				matrix[partner * MAX_DIMENSION + k] = temporary
			}
			for k := 0; k < dimension; k += 1 {
				temporary := matrix[k * MAX_DIMENSION + swapped]
				matrix[k * MAX_DIMENSION + swapped] = matrix[k * MAX_DIMENSION + partner]
				matrix[k * MAX_DIMENSION + partner] = temporary
			}
			result = if result == 0 { 0 } else { MODULUS - result }
		}

		first, second := pivot_index * MAX_DIMENSION, (pivot_index + 1) * MAX_DIMENSION
		pivot := matrix[first + pivot_index + 1]
		result = multiply(result, pivot)
		inverse := power(pivot, MODULUS - 2)
		for row := pivot_index + 2; row < dimension; row += 1 {
			for column := row + 1; column < dimension; column += 1 {
				cross := normalize(multiply(matrix[first + row], matrix[second + column]) -
					multiply(matrix[first + column], matrix[second + row]))
				value := normalize(matrix[row * MAX_DIMENSION + column] - multiply(cross, inverse))
				matrix[row * MAX_DIMENSION + column] = value
				matrix[column * MAX_DIMENSION + row] = if value == 0 { 0 } else { MODULUS - value }
			}
		}
	}
	return result
}
