module all_pairs_directed_random_walk_hitting_times

const max_n = 8
const matrix_width = 17
const max_input_length = 115
const modulus = i64(1000000007)

fn rw_norm(input i64) i64 {
	mut value := input % modulus
	if value < 0 { value += modulus }
	return value
}

fn rw_power(base_input i64, exponent_input i64) i64 {
	mut base := rw_norm(base_input)
	mut exponent := exponent_input
	mut result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 { result = result * base % modulus }
		base = base * base % modulus
		exponent >>= 1
	}
	return result
}

fn rw_reaches_all(graph [max_n][max_n]bool, n int, reverse bool) bool {
	mut seen := [max_n]bool{}
	mut queue := [max_n]int{}
	mut head := 0
	mut tail := 1
	seen[0] = true
	queue[0] = 0
	for head < tail {
		current := queue[head]
		head++
		for to in 0 .. n {
			has_edge := if reverse { graph[to][current] } else { graph[current][to] }
			if has_edge && !seen[to] {
				seen[to] = true
				queue[tail] = to
				tail++
			}
		}
	}
	return tail == n
}

fn rw_eliminate(mut matrix [max_n][matrix_width]i64, size int, rhs_count int) bool {
	width := size + rhs_count
	for column in 0 .. size {
		mut pivot := column
		for pivot < size && rw_norm(matrix[pivot][column]) == 0 { pivot++ }
		if pivot == size { return false }
		if pivot != column { matrix[pivot], matrix[column] = matrix[column], matrix[pivot] }
		inverse := rw_power(matrix[column][column], modulus - 2)
		for j in 0 .. width { matrix[column][j] = matrix[column][j] * inverse % modulus }
		for row in 0 .. size {
			if row == column { continue }
			factor := rw_norm(matrix[row][column])
			if factor == 0 { continue }
			for j in 0 .. width {
				matrix[row][j] = rw_norm(matrix[row][j] - factor * matrix[column][j] % modulus)
			}
		}
	}
	return true
}

fn rw_store_i64(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'all_pairs_directed_random_walk_hitting_times']
pub fn all_pairs_directed_random_walk_hitting_times(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input_length { return -1 }
		n_value, m_value := input[0], input[1]
		if n_value < 3 || n_value > max_n { return -1 }
		if m_value < 0 || m_value > n_value * (n_value - 1) { return -1 }
		n, m := int(n_value), int(m_value)
		if length != usize(2 + 2*m) { return -1 }
		mut graph := [max_n][max_n]bool{}
		mut degree := [max_n]int{}
		for edge in 0 .. m {
			u_value, v_value := input[2 + 2*edge], input[3 + 2*edge]
			if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value { return -1 }
			u, v := int(u_value), int(v_value)
			if graph[u][v] { return -1 }
			graph[u][v] = true
			degree[u]++
		}
		for vertex in 0 .. n { if degree[vertex] == 0 { return -1 } }
		if !rw_reaches_all(graph, n, false) || !rw_reaches_all(graph, n, true) { return -1 }
		output_bytes := 8*n*n
		if output == nil || capacity < usize(output_bytes) { return -2 }

		mut stationary := [max_n][matrix_width]i64{}
		for destination in 0 .. n - 1 {
			for source in 0 .. n {
				transition := i64(0)
				if graph[source][destination] { transition = rw_power(i64(degree[source]), modulus - 2) }
				identity := i64(0)
				if source == destination { identity = 1 }
				stationary[destination][source] = rw_norm(transition - identity)
			}
		}
		for source in 0 .. n { stationary[n - 1][source] = 1 }
		stationary[n - 1][n] = 1
		if !rw_eliminate(mut stationary, n, 1) { return -1 }
		mut reciprocal := [max_n]i64{}
		for vertex in 0 .. n {
			pi := rw_norm(stationary[vertex][n])
			if pi == 0 { return -1 }
			reciprocal[vertex] = rw_power(pi, modulus - 2)
		}

		mut reduced := [max_n][matrix_width]i64{}
		for row in 0 .. n - 1 {
			for column in 0 .. n - 1 {
				transition := i64(0)
				if graph[row][column] { transition = rw_power(i64(degree[row]), modulus - 2) }
				identity := i64(0)
				if row == column { identity = 1 }
				reduced[row][column] = rw_norm(identity - transition)
			}
			for target in 0 .. n {
				correction := i64(0)
				if row == target { correction = reciprocal[target] }
				reduced[row][n - 1 + target] = rw_norm(1 - correction)
			}
		}
		if !rw_eliminate(mut reduced, n - 1, n) { return -1 }
		mut y := [max_n][max_n]i64{}
		for row in 0 .. n - 1 { for target in 0 .. n { y[row][target] = rw_norm(reduced[row][n - 1 + target]) } }
		for source in 0 .. n {
			for target in 0 .. n {
				rw_store_i64(mut output, 8*(source*n+target), rw_norm(y[source][target] - y[target][target]))
			}
		}
		return i64(output_bytes)
	}
}
