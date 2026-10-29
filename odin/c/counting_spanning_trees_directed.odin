package counting_spanning_trees_directed

import "core:c"

MODULUS :: i64(998_244_353)

modular_power :: proc(base_value, exponent_value: i64) -> i64 {
	base, exponent := base_value, exponent_value
	result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 do result = (result * base) % MODULUS
		base = (base * base) % MODULUS
		exponent >>= 1
	}
	return result
}

@(export)
counting_spanning_trees_directed :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 27 do return -1
	n_value, m_value, root_value := input[0], input[1], input[2]
	if n_value < 1 || n_value > 6 || m_value < 0 || m_value > 12 || root_value < 0 || root_value >= n_value do return -1
	n, edge_count, root := int(n_value), int(m_value), int(root_value)
	if length != c.size_t(3 + 2*edge_count) do return -1

	dimension := n - 1
	matrix: [6][6]i64 = 0
	for edge := 0; edge < edge_count; edge += 1 {
		u_value, v_value := input[3+2*edge], input[4+2*edge]
		if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value do return -1
		u, v := int(u_value), int(v_value)
		if u != v && v != root {
			row := v
			if v > root do row -= 1
			matrix[row][row] = (matrix[row][row] + 1) % MODULUS
			if u != root {
				column := u
				if u > root do column -= 1
				matrix[row][column] = (matrix[row][column] + MODULUS - 1) % MODULUS
			}
		}
	}
	if output == nil || output_capacity < 8 do return -2

	determinant := i64(1)
	for column := 0; column < dimension; column += 1 {
		pivot := column
		for pivot < dimension && matrix[pivot][column] == 0 { pivot += 1 }
		if pivot == dimension { determinant = 0; break }
		if pivot != column {
			for j := 0; j < dimension; j += 1 {
				temporary := matrix[column][j]
				matrix[column][j], matrix[pivot][j] = matrix[pivot][j], temporary
			}
			determinant = (MODULUS - determinant) % MODULUS
		}
		pivot_value := matrix[column][column]
		determinant = (determinant * pivot_value) % MODULUS
		inverse := modular_power(pivot_value, MODULUS-2)
		for row := column + 1; row < dimension; row += 1 {
			factor := (matrix[row][column] * inverse) % MODULUS
			for j := column; j < dimension; j += 1 {
				matrix[row][j] = (matrix[row][j] - factor*matrix[column][j]%MODULUS + MODULUS) % MODULUS
			}
		}
	}
	answer := u64(determinant)
	for byte := 0; byte < 8; byte += 1 { output[byte] = u8((answer >> (8*byte)) & 0xff) }
	return 8
}
