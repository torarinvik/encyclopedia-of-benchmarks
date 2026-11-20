module tutte_matrix_randomized_perfect_matching

import c

const max_n = 8
const max_edges = 28
const max_input = 87
const max_output = 80
const field_p = i64(65521)

fn norm(value i64) i64 {
	mut result := value % field_p
	if result < 0 { result += field_p }
	return result
}

fn mod_pow(base i64, exponent_value u64) i64 {
	mut exponent := exponent_value
	mut result := i64(1)
	mut factor := norm(base)
	for exponent != 0 {
		if (exponent & 1) != 0 { result = result * factor % field_p }
		factor = factor * factor % field_p
		exponent >>= 1
	}
	return result
}

fn store_word(mut bytes []u8, word int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { bytes[word*8+byte] = u8((bits >> (8*byte)) & 255) }
}

fn eliminate(mut inverse []i64, mut rows []bool, mut columns []bool,
	n int, pivot_row int, pivot_column int) bool {
	mut old := []i64{len: max_n*max_n, init: 0}
	for index in 0 .. max_n*max_n { old[index] = inverse[index] }
	pivot := old[pivot_row*max_n+pivot_column]
	if pivot == 0 { return false }
	inverse_pivot := mod_pow(pivot, u64(field_p-2))
	for row in 0 .. n {
		for column in 0 .. n {
			index := row*max_n+column
			if rows[row] && row != pivot_row && columns[column] && column != pivot_column {
				correction := old[row*max_n+pivot_column] * old[pivot_row*max_n+column] % field_p
				inverse[index] = norm(old[index]-correction*inverse_pivot)
			} else { inverse[index] = 0 }
		}
	}
	rows[pivot_row] = false
	columns[pivot_column] = false
	return true
}

@[export: 'tutte_matrix_randomized_perfect_matching']
pub fn tutte_matrix_randomized_perfect_matching(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return -1 }
		n_value, edge_count_value := input[0], input[1]
		if n_value < 2 || n_value > max_n || (n_value & 1) != 0 ||
			edge_count_value < 0 || edge_count_value > max_edges { return -1 }
		n, edge_count := int(n_value), int(edge_count_value)
		if edge_count > n*(n-1)/2 || length != usize(2+3*edge_count) { return -1 }

		mut matrix := []i64{len: max_n*max_n, init: 0}
		mut previous_u, mut previous_v := i64(-1), i64(-1)
		for edge in 0 .. edge_count {
			u_value, v_value, substitution := input[2+3*edge], input[3+3*edge], input[4+3*edge]
			if u_value < 0 || v_value <= u_value || v_value >= n_value ||
				u_value < previous_u || (u_value == previous_u && v_value <= previous_v) ||
				substitution < 1 || substitution >= field_p { return -1 }
			u, v := int(u_value), int(v_value)
			matrix[u*max_n+v] = substitution
			matrix[v*max_n+u] = field_p-substitution
			previous_u, previous_v = u_value, v_value
		}

		mut augmented := []i64{len: max_n*2*max_n, init: 0}
		for row in 0 .. n {
			for column in 0 .. n { augmented[row*2*max_n+column] = matrix[row*max_n+column] }
			augmented[row*2*max_n+n+row] = 1
		}
		mut singular := false
		for column in 0 .. n {
			mut pivot_row := column
			for pivot_row < n && augmented[pivot_row*2*max_n+column] == 0 { pivot_row++ }
			if pivot_row == n { singular = true; break }
			if pivot_row != column {
				for j in 0 .. 2*n {
					temp := augmented[column*2*max_n+j]
					augmented[column*2*max_n+j] = augmented[pivot_row*2*max_n+j]
					augmented[pivot_row*2*max_n+j] = temp
				}
			}
			inverse_pivot := mod_pow(augmented[column*2*max_n+column], u64(field_p-2))
			for j in 0 .. 2*n { augmented[column*2*max_n+j] = augmented[column*2*max_n+j]*inverse_pivot%field_p }
			for row in 0 .. n {
				if row == column { continue }
				factor := augmented[row*2*max_n+column]
				if factor == 0 { continue }
				for j in 0 .. 2*n { augmented[row*2*max_n+j] = norm(augmented[row*2*max_n+j]-factor*augmented[column*2*max_n+j]) }
			}
		}

		mut result := []i64{len: 2+max_n, init: 0}
		mut result_size := 2
		if !singular {
			mut inverse := []i64{len: max_n*max_n, init: 0}
			for row in 0 .. n {
				for column in 0 .. n { inverse[row*max_n+column] = augmented[row*2*max_n+n+column] }
			}
			mut rows := []bool{len: max_n, init: false}
			mut columns := []bool{len: max_n, init: false}
			for i in 0 .. n { rows[i] = true; columns[i] = true }
			mut failed := false
			for vertex in 0 .. n {
				if !columns[vertex] { continue }
				mut partner := -1
				for candidate in 0 .. n {
					if rows[candidate] && candidate != vertex && matrix[vertex*max_n+candidate] != 0 && inverse[candidate*max_n+vertex] != 0 {
						partner = candidate
						break
					}
				}
				if partner < 0 || result_size+2 > 2+max_n { failed = true; break }
				result[result_size] = i64(vertex)
				result[result_size+1] = i64(partner)
				result_size += 2
				if !eliminate(mut inverse, mut rows, mut columns, n, partner, vertex) ||
					!eliminate(mut inverse, mut rows, mut columns, n, vertex, partner) { failed = true; break }
			}
			if failed { result_size = 2 } else { result[0] = 1; result[1] = i64(n/2) }
		}
		output_bytes := result_size*8
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut staged := []u8{len: max_output, init: 0}
		for word in 0 .. result_size { store_word(mut staged, word, result[word]) }
		for byte in 0 .. output_bytes { output[byte] = staged[byte] }
		return i64(output_bytes)
	}
}
