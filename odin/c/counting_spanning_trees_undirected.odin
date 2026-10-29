package counting_spanning_trees_undirected

import "core:c"

MODULUS :: i64(1_000_000_007)

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
counting_spanning_trees_undirected :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 44 do return -1
	n_value, m_value := input[0], input[1]
	if n_value < 1 || n_value > 7 || m_value < 0 || m_value > 21 do return -1
	n, edge_count := int(n_value), int(m_value)
	if length != c.size_t(2 + 2*edge_count) do return -1

	adjacent: [7][7]bool = 0
	for edge := 0; edge < edge_count; edge += 1 {
		u_value, v_value := input[2+2*edge], input[3+2*edge]
		if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value do return -1
		u, v := int(u_value), int(v_value)
		if adjacent[u][v] do return -1
		adjacent[u][v], adjacent[v][u] = true, true
	}
	if output == nil || output_capacity < 8 do return -2

	dimension := n - 1
	matrix: [7][7]i64 = 0
	for row := 0; row < dimension; row += 1 {
		degree := i64(0)
		for column := 0; column < n; column += 1 {
			if !adjacent[row][column] do continue
			degree += 1
			if column < dimension do matrix[row][column] = MODULUS - 1
		}
		matrix[row][row] = degree
	}

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
