package matrix_det_arbitrary_mod

import "core:c"

MAX_N :: 8
MAX_INPUT_VALUES :: 2 + MAX_N * MAX_N + 1
MAX_MODULUS :: i64(1_000_000_000)

normalize :: proc "contextless" (value, modulus: i64) -> i64 {
	residue := value % modulus
	if residue < 0 do residue += modulus
	return residue
}

store_i64_le :: proc "contextless" (output: [^]u8, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
matrix_det_arbitrary_mod :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_VALUES do return -1
	n_value, modulus := input[0], input[1]
	if n_value < 0 || n_value > i64(MAX_N) || modulus < 2 || modulus > MAX_MODULUS do return -1
	n := int(n_value)
	if length != c.size_t(2 + n * n) do return -1

	matrix: [MAX_N * MAX_N]i64
	for index := 0; index < MAX_N * MAX_N; index += 1 { matrix[index] = 0 }
	for row := 0; row < n; row += 1 {
		for column := 0; column < n; column += 1 {
			value := input[2 + row * n + column]
			if value < 0 || value >= modulus do return -1
			matrix[row * n + column] = value
		}
	}

	determinant := i64(1)
	sign := false
	for column := 0; column < n; column += 1 {
		pivot := column
		for pivot < n && matrix[pivot * n + column] == 0 do pivot += 1
		if pivot == n {
			determinant = 0
			break
		}
		if pivot != column {
			for k := 0; k < n; k += 1 {
				temporary := matrix[column * n + k]
				matrix[column * n + k] = matrix[pivot * n + k]
				matrix[pivot * n + k] = temporary
			}
			sign = !sign
		}
		for row := column + 1; row < n; row += 1 {
			left, right := matrix[column * n + column], matrix[row * n + column]
			if right == 0 do continue
			a0, a1, b0, b1 := i64(1), i64(0), i64(0), i64(1)
			for left != 0 && right != 0 {
				if left < right {
					quotient := right / left
					right -= quotient * left
					b0 = normalize(b0 - a0 * quotient, modulus)
					b1 = normalize(b1 - a1 * quotient, modulus)
				} else {
					quotient := left / right
					left -= quotient * right
					a0 = normalize(a0 - b0 * quotient, modulus)
					a1 = normalize(a1 - b1 * quotient, modulus)
				}
			}
			for k := column; k < n; k += 1 {
				old_top, old_bottom := matrix[column * n + k], matrix[row * n + k]
				matrix[column * n + k] = normalize(old_top * a0 + old_bottom * a1, modulus)
				matrix[row * n + k] = normalize(old_top * b0 + old_bottom * b1, modulus)
			}
			if left == 0 {
				for k := 0; k < n; k += 1 {
					temporary := matrix[column * n + k]
					matrix[column * n + k] = matrix[row * n + k]
					matrix[row * n + k] = temporary
				}
				sign = !sign
			}
		}
		determinant = determinant * matrix[column * n + column] % modulus
		if determinant == 0 do break
	}
	if sign && determinant != 0 do determinant = modulus - determinant
	if output == nil || capacity < 8 do return -2
	store_i64_le(output, determinant)
	return 8
}
