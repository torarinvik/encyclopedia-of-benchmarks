package characteristic_polynomial

import "core:c"

MODULUS :: i64(998244353)
MAX_N :: 8
MAX_INPUT_VALUES :: 1 + MAX_N * MAX_N + 1

normalize :: proc(value: i64) -> i64 {
	result := value % MODULUS
	if result < 0 do result += MODULUS
	return result
}

multiply :: proc(left, right: i64) -> i64 {
	return (left * right) % MODULUS
}

power :: proc(base_value, exponent_value: i64) -> i64 {
	base := base_value
	exponent := exponent_value
	result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 do result = multiply(result, base)
		base = multiply(base, base)
		exponent >>= 1
	}
	return result
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
characteristic_polynomial :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_VALUES do return -1
	n_value := input[0]
	if n_value < 0 || n_value > i64(MAX_N) do return -1
	n := int(n_value)
	if length != c.size_t(1 + n * n) do return -1

	matrix: [MAX_N * MAX_N]i64
	for row := 0; row < n; row += 1 {
		for column := 0; column < n; column += 1 {
			value := input[1 + row * n + column]
			if value < 0 || value >= MODULUS do return -1
			matrix[row * MAX_N + column] = value
		}
	}

	for column := 0; column + 2 < n; column += 1 {
		pivot := column + 1
		for pivot < n && matrix[pivot * MAX_N + column] == 0 do pivot += 1
		if pivot == n do continue
		if pivot != column + 1 {
			for k := 0; k < n; k += 1 {
				temporary := matrix[(column + 1) * MAX_N + k]
				matrix[(column + 1) * MAX_N + k] = matrix[pivot * MAX_N + k]
				matrix[pivot * MAX_N + k] = temporary
			}
			for k := 0; k < n; k += 1 {
				temporary := matrix[k * MAX_N + column + 1]
				matrix[k * MAX_N + column + 1] = matrix[k * MAX_N + pivot]
				matrix[k * MAX_N + pivot] = temporary
			}
		}
		inverse := power(matrix[(column + 1) * MAX_N + column], MODULUS - 2)
		for row := column + 2; row < n; row += 1 {
			if matrix[row * MAX_N + column] == 0 do continue
			factor := multiply(matrix[row * MAX_N + column], inverse)
			for k := 0; k < n; k += 1 {
				matrix[row * MAX_N + k] = normalize(
					matrix[row * MAX_N + k] - multiply(factor, matrix[(column + 1) * MAX_N + k]))
			}
			for k := 0; k < n; k += 1 {
				matrix[k * MAX_N + column + 1] = normalize(
					matrix[k * MAX_N + column + 1] + multiply(factor, matrix[k * MAX_N + row]))
			}
		}
	}

	coefficients: [(MAX_N + 1) * (MAX_N + 1)]i64
	coefficients[0] = 1
	for size := 1; size <= n; size += 1 {
		for degree := 0; degree <= size; degree += 1 {
			value := i64(0)
			if degree > 0 do value = coefficients[(size - 1) * (MAX_N + 1) + degree - 1]
			if degree < size {
				value -= multiply(matrix[(size - 1) * MAX_N + size - 1],
					coefficients[(size - 1) * (MAX_N + 1) + degree])
			}
			coefficients[size * (MAX_N + 1) + degree] = normalize(value)
		}
		subdiagonal_product := i64(1)
		for start := size - 2; start >= 0; start -= 1 {
			subdiagonal_product = multiply(subdiagonal_product,
				matrix[(start + 1) * MAX_N + start])
			term := multiply(subdiagonal_product, matrix[start * MAX_N + size - 1])
			for degree := 0; degree <= start; degree += 1 {
				coefficients[size * (MAX_N + 1) + degree] = normalize(
					coefficients[size * (MAX_N + 1) + degree] -
					multiply(term, coefficients[start * (MAX_N + 1) + degree]))
			}
		}
	}

	output_bytes := c.size_t(8 * (n + 1))
	if output == nil || capacity < output_bytes do return -2
	for degree := 0; degree <= n; degree += 1 {
		store_i64_le(output, 8 * degree, coefficients[n * (MAX_N + 1) + degree])
	}
	return i64(output_bytes)
}
