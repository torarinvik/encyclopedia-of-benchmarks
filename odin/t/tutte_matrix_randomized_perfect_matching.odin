package tutte_matrix_randomized_perfect_matching

import "core:c"

MAX_N :: 8
MAX_EDGES :: 28
MAX_INPUT :: 87
MAX_OUTPUT :: 80
FIELD_P :: i64(65521)

norm :: proc(value: i64) -> i64 {
	result := value % FIELD_P
	if result < 0 { result += FIELD_P }
	return result
}

mod_pow :: proc(base: i64, exponent_value: u64) -> i64 {
	exponent := exponent_value
	result := i64(1)
	factor := norm(base)
	for exponent != 0 {
		if (exponent & 1) != 0 { result = result * factor % FIELD_P }
		factor = factor * factor % FIELD_P
		exponent >>= 1
	}
	return result
}

store_word :: proc(bytes: [^]u8, word: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		bytes[word*8+byte] = u8(bits & 255)
		bits >>= 8
	}
}

eliminate :: proc(inverse: []i64, rows: []bool, columns: []bool,
	n, pivot_row, pivot_column: int) -> bool {
	old: [MAX_N*MAX_N]i64
	for index := 0; index < MAX_N*MAX_N; index += 1 { old[index] = inverse[index] }
	pivot := old[pivot_row*MAX_N+pivot_column]
	if pivot == 0 { return false }
	inverse_pivot := mod_pow(pivot, u64(FIELD_P-2))
	for row := 0; row < n; row += 1 {
		for column := 0; column < n; column += 1 {
			index := row*MAX_N+column
			if rows[row] && row != pivot_row && columns[column] && column != pivot_column {
				correction := old[row*MAX_N+pivot_column] * old[pivot_row*MAX_N+column] % FIELD_P
				inverse[index] = norm(old[index] - correction*inverse_pivot)
			} else { inverse[index] = 0 }
		}
	}
	rows[pivot_row] = false
	columns[pivot_column] = false
	return true
}

@(export)
tutte_matrix_randomized_perfect_matching :: proc "c" (input: [^]i64,
	length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	n_value, edge_count_value := input[0], input[1]
	if n_value < 2 || n_value > MAX_N || (n_value & 1) != 0 ||
		edge_count_value < 0 || edge_count_value > MAX_EDGES do return -1
	n, edge_count := int(n_value), int(edge_count_value)
	if edge_count > n*(n-1)/2 || length != c.size_t(2+3*edge_count) do return -1

	matrix: [MAX_N*MAX_N]i64
	previous_u, previous_v := i64(-1), i64(-1)
	for edge := 0; edge < edge_count; edge += 1 {
		u_value, v_value, substitution := input[2+3*edge], input[3+3*edge], input[4+3*edge]
		if u_value < 0 || v_value <= u_value || v_value >= n_value ||
			u_value < previous_u || (u_value == previous_u && v_value <= previous_v) ||
			substitution < 1 || substitution >= FIELD_P do return -1
		u, v := int(u_value), int(v_value)
		matrix[u*MAX_N+v] = substitution
		matrix[v*MAX_N+u] = FIELD_P-substitution
		previous_u, previous_v = u_value, v_value
	}

	augmented: [MAX_N*2*MAX_N]i64
	for row := 0; row < n; row += 1 {
		for column := 0; column < n; column += 1 { augmented[row*2*MAX_N+column] = matrix[row*MAX_N+column] }
		augmented[row*2*MAX_N+n+row] = 1
	}
	singular := false
	for column := 0; column < n; column += 1 {
		pivot_row := column
		for pivot_row < n && augmented[pivot_row*2*MAX_N+column] == 0 { pivot_row += 1 }
		if pivot_row == n { singular = true; break }
		if pivot_row != column {
			for j := 0; j < 2*n; j += 1 {
				temp := augmented[column*2*MAX_N+j]
				augmented[column*2*MAX_N+j] = augmented[pivot_row*2*MAX_N+j]
				augmented[pivot_row*2*MAX_N+j] = temp
			}
		}
		inverse_pivot := mod_pow(augmented[column*2*MAX_N+column], u64(FIELD_P-2))
		for j := 0; j < 2*n; j += 1 { augmented[column*2*MAX_N+j] = augmented[column*2*MAX_N+j]*inverse_pivot%FIELD_P }
		for row := 0; row < n; row += 1 {
			if row == column { continue }
			factor := augmented[row*2*MAX_N+column]
			if factor == 0 { continue }
			for j := 0; j < 2*n; j += 1 { augmented[row*2*MAX_N+j] = norm(augmented[row*2*MAX_N+j]-factor*augmented[column*2*MAX_N+j]) }
		}
	}

	result: [2+MAX_N]i64
	result_size := 2
	if !singular {
		inverse: [MAX_N*MAX_N]i64
		for row := 0; row < n; row += 1 {
			for column := 0; column < n; column += 1 { inverse[row*MAX_N+column] = augmented[row*2*MAX_N+n+column] }
		}
		rows: [MAX_N]bool
		columns: [MAX_N]bool
		for i := 0; i < n; i += 1 { rows[i] = true; columns[i] = true }
		failed := false
		for vertex := 0; vertex < n; vertex += 1 {
			if !columns[vertex] { continue }
			partner := -1
			for candidate := 0; candidate < n; candidate += 1 {
				if rows[candidate] && candidate != vertex && matrix[vertex*MAX_N+candidate] != 0 && inverse[candidate*MAX_N+vertex] != 0 {
					partner = candidate
					break
				}
			}
			if partner < 0 || result_size+2 > 2+MAX_N { failed = true; break }
			result[result_size] = i64(vertex)
			result[result_size+1] = i64(partner)
			result_size += 2
			if !eliminate(inverse[:], rows[:], columns[:], n, partner, vertex) ||
				!eliminate(inverse[:], rows[:], columns[:], n, vertex, partner) { failed = true; break }
		}
		if failed { result_size = 2 } else { result[0] = 1; result[1] = i64(n/2) }
	}
	output_bytes := result_size*8
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	staged: [MAX_OUTPUT]u8
	for word := 0; word < result_size; word += 1 { store_word(&staged[0], word, result[word]) }
	for byte := 0; byte < output_bytes; byte += 1 { output[byte] = staged[byte] }
	return i64(output_bytes)
}
