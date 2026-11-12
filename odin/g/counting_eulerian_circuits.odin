package counting_eulerian_circuits

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
counting_eulerian_circuits :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 20 do return -1
	n_value, m_value := input[0], input[1]
	if n_value < 1 || n_value > 7 || m_value < 1 || m_value > 9 do return -1
	n, edge_count := int(n_value), int(m_value)
	if length != c.size_t(2 + 2*edge_count) do return -1

	indegree: [7]int = 0
	outdegree: [7]int = 0
	start := 0
	for edge := 0; edge < edge_count; edge += 1 {
		u_value, v_value := input[2+2*edge], input[3+2*edge]
		if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value do return -1
		u, v := int(u_value), int(v_value)
		if edge == 0 do start = u
		outdegree[u] += 1
		indegree[v] += 1
	}

	balanced := true
	for vertex := 0; vertex < n; vertex += 1 {
		if indegree[vertex] != outdegree[vertex] do balanced = false
	}

	answer := i64(0)
	if balanced {
		active_id: [7]int
		active_count := 0
		for vertex := 0; vertex < n; vertex += 1 {
			active_id[vertex] = 7
			if indegree[vertex] != 0 { active_id[vertex] = active_count; active_count += 1 }
		}
		root_id := active_id[start]
		dimension := active_count - 1
		matrix: [7][7]i64 = 0
		for edge := 0; edge < edge_count; edge += 1 {
			u, v := int(input[2+2*edge]), int(input[3+2*edge])
			if u == start do continue
			row := active_id[u]
			if row > root_id do row -= 1
			matrix[row][row] = (matrix[row][row] + 1) % MODULUS
			if v != start {
				column := active_id[v]
				if column > root_id do column -= 1
				matrix[row][column] = (matrix[row][column] + MODULUS - 1) % MODULUS
			}
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
		answer = determinant
		for vertex := 0; vertex < n; vertex += 1 {
			for factor := 2; factor < outdegree[vertex]; factor += 1 { answer = (answer * i64(factor)) % MODULUS }
		}
	}

	if output == nil || output_capacity < 8 do return -2
	encoded := u64(answer)
	for byte := 0; byte < 8; byte += 1 { output[byte] = u8((encoded >> (8*byte)) & 0xff) }
	return 8
}
