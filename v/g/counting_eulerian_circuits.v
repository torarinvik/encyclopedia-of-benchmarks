module counting_eulerian_circuits

const modulus = i64(998_244_353)

fn modular_power(base_value i64, exponent_value i64) i64 {
	mut base := base_value
	mut exponent := exponent_value
	mut result := i64(1)
	for exponent > 0 {
		if exponent & 1 != 0 { result = (result * base) % modulus }
		base = (base * base) % modulus
		exponent >>= 1
	}
	return result
}

@[export: 'counting_eulerian_circuits']
pub fn counting_eulerian_circuits(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if input == nil || length < 2 || length > 20 { return -1 }
	n_value := unsafe { input[0] }
	m_value := unsafe { input[1] }
	if n_value < 1 || n_value > 7 || m_value < 1 || m_value > 9 { return -1 }
	n := int(n_value)
	edge_count := int(m_value)
	if length != usize(2 + 2*edge_count) { return -1 }

	mut indegree := [7]int{}
	mut outdegree := [7]int{}
	mut start := 0
	for edge in 0 .. edge_count {
		u_value := unsafe { input[2+2*edge] }
		v_value := unsafe { input[3+2*edge] }
		if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value { return -1 }
		u := int(u_value)
		v := int(v_value)
		if edge == 0 { start = u }
		outdegree[u]++
		indegree[v]++
	}

	mut balanced := true
	for vertex in 0 .. n { if indegree[vertex] != outdegree[vertex] { balanced = false } }
	mut answer := i64(0)
	if balanced {
		mut active_id := [7]int{}
		mut active_count := 0
		for vertex in 0 .. n {
			active_id[vertex] = 7
			if indegree[vertex] != 0 { active_id[vertex] = active_count; active_count++ }
		}
		root_id := active_id[start]
		dimension := active_count - 1
		mut matrix := [7][7]i64{}
		for edge in 0 .. edge_count {
			u := int(unsafe { input[2+2*edge] })
			v := int(unsafe { input[3+2*edge] })
			if u == start { continue }
			mut row := active_id[u]
			if row > root_id { row-- }
			matrix[row][row] = (matrix[row][row] + 1) % modulus
			if v != start {
				mut column := active_id[v]
				if column > root_id { column-- }
				matrix[row][column] = (matrix[row][column] + modulus - 1) % modulus
			}
		}

		mut determinant := i64(1)
		for column in 0 .. dimension {
			mut pivot := column
			for pivot < dimension && matrix[pivot][column] == 0 { pivot++ }
			if pivot == dimension { determinant = 0; break }
			if pivot != column {
				for j in 0 .. dimension {
					temporary := matrix[column][j]
					matrix[column][j] = matrix[pivot][j]
					matrix[pivot][j] = temporary
				}
				determinant = (modulus - determinant) % modulus
			}
			pivot_value := matrix[column][column]
			determinant = (determinant * pivot_value) % modulus
			inverse := modular_power(pivot_value, modulus - 2)
			for row in column + 1 .. dimension {
				factor := (matrix[row][column] * inverse) % modulus
				for j in column .. dimension {
					matrix[row][j] = (matrix[row][j] - factor*matrix[column][j]%modulus + modulus) % modulus
				}
			}
		}
		answer = determinant
		for vertex in 0 .. n {
			for factor in 2 .. outdegree[vertex] { answer = (answer * i64(factor)) % modulus }
		}
	}
	if output == nil || output_capacity < 8 { return -2 }
	encoded := u64(answer)
	unsafe { for byte in 0 .. 8 { output[byte] = u8((encoded >> (8*byte)) & 0xff) } }
	return 8
}
