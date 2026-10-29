module counting_spanning_trees_undirected

const modulus = i64(1_000_000_007)

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

@[export: 'counting_spanning_trees_undirected']
pub fn counting_spanning_trees_undirected(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if input == nil || length < 2 || length > 44 { return -1 }
	n_value := unsafe { input[0] }
	m_value := unsafe { input[1] }
	if n_value < 1 || n_value > 7 || m_value < 0 || m_value > 21 { return -1 }
	n := int(n_value)
	edge_count := int(m_value)
	if length != usize(2 + 2*edge_count) { return -1 }

	mut adjacent := [7][7]bool{}
	for edge in 0 .. edge_count {
		u_value := unsafe { input[2+2*edge] }
		v_value := unsafe { input[3+2*edge] }
		if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value { return -1 }
		u := int(u_value)
		v := int(v_value)
		if adjacent[u][v] { return -1 }
		adjacent[u][v] = true
		adjacent[v][u] = true
	}
	if output == nil || output_capacity < 8 { return -2 }

	dimension := n - 1
	mut matrix := [7][7]i64{}
	for row in 0 .. dimension {
		mut degree := i64(0)
		for column in 0 .. n {
			if adjacent[row][column] {
				degree++
				if column < dimension { matrix[row][column] = modulus - 1 }
			}
		}
		matrix[row][row] = degree
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
	answer := u64(determinant)
	unsafe { for byte in 0 .. 8 { output[byte] = u8((answer >> (8*byte)) & 0xff) } }
	return 8
}
