package all_pairs_directed_random_walk_hitting_times

import "core:c"

MAX_N :: 8
MATRIX_WIDTH :: 17
MAX_INPUT_LENGTH :: 115
MODULUS :: i64(1_000_000_007)
Matrix :: [MAX_N][MATRIX_WIDTH]i64

norm :: proc "contextless" (value_input: i64) -> i64 {
	value := value_input % MODULUS
	if value < 0 { value += MODULUS }
	return value
}

power :: proc "contextless" (base_input, exponent_input: i64) -> i64 {
	base, exponent, result := norm(base_input), exponent_input, i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 { result = result * base % MODULUS }
		base = base * base % MODULUS
		exponent >>= 1
	}
	return result
}

reaches_all :: proc "contextless" (graph: [MAX_N][MAX_N]bool, n: int, reverse: bool) -> bool {
	seen: [MAX_N]bool
	queue: [MAX_N]int
	head, tail := 0, 1
	seen[0], queue[0] = true, 0
	for head < tail {
		current := queue[head]
		head += 1
		for to := 0; to < n; to += 1 {
			has_edge := graph[current][to]
			if reverse { has_edge = graph[to][current] }
			if has_edge && !seen[to] {
				seen[to] = true
				queue[tail] = to
				tail += 1
			}
		}
	}
	return tail == n
}

eliminate :: proc "contextless" (matrix: ^Matrix, size, rhs_count: int) -> bool {
	width := size + rhs_count
	for column := 0; column < size; column += 1 {
		pivot := column
		for pivot < size && norm(matrix^[pivot][column]) == 0 { pivot += 1 }
		if pivot == size { return false }
		if pivot != column { matrix^[pivot], matrix^[column] = matrix^[column], matrix^[pivot] }
		inverse := power(matrix^[column][column], MODULUS-2)
		for j := 0; j < width; j += 1 { matrix^[column][j] = matrix^[column][j] * inverse % MODULUS }
		for row := 0; row < size; row += 1 {
			if row == column { continue }
			factor := norm(matrix^[row][column])
			if factor == 0 { continue }
			for j := 0; j < width; j += 1 {
				matrix^[row][j] = norm(matrix^[row][j] - factor * matrix^[column][j] % MODULUS)
			}
		}
	}
	return true
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
all_pairs_directed_random_walk_hitting_times :: proc "c" (input: [^]i64,
	length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) { return -1 }
	n_value, m_value := input[0], input[1]
	if n_value < 3 || n_value > i64(MAX_N) { return -1 }
	if m_value < 0 || m_value > n_value*(n_value-1) { return -1 }
	n, m := int(n_value), int(m_value)
	if length != c.size_t(2+2*m) { return -1 }
	graph: [MAX_N][MAX_N]bool
	degree: [MAX_N]int
	for e := 0; e < m; e += 1 {
		u_value, v_value := input[2+2*e], input[3+2*e]
		if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value { return -1 }
		u, v := int(u_value), int(v_value)
		if graph[u][v] { return -1 }
		graph[u][v] = true
		degree[u] += 1
	}
	for vertex := 0; vertex < n; vertex += 1 { if degree[vertex] == 0 { return -1 } }
	if !reaches_all(graph, n, false) || !reaches_all(graph, n, true) { return -1 }
	output_bytes := 8*n*n
	if output == nil || capacity < c.size_t(output_bytes) { return -2 }

	stationary: Matrix
	for destination := 0; destination < n-1; destination += 1 {
		for source := 0; source < n; source += 1 {
			transition := i64(0)
			if graph[source][destination] { transition = power(i64(degree[source]), MODULUS-2) }
			identity := i64(0)
			if source == destination { identity = 1 }
			stationary[destination][source] = norm(transition-identity)
		}
	}
	for source := 0; source < n; source += 1 { stationary[n-1][source] = 1 }
	stationary[n-1][n] = 1
	if !eliminate(&stationary, n, 1) { return -1 }
	reciprocal: [MAX_N]i64
	for vertex := 0; vertex < n; vertex += 1 {
		pi := norm(stationary[vertex][n])
		if pi == 0 { return -1 }
		reciprocal[vertex] = power(pi, MODULUS-2)
	}

	reduced: Matrix
	for row := 0; row < n-1; row += 1 {
		for column := 0; column < n-1; column += 1 {
			transition := i64(0)
			if graph[row][column] { transition = power(i64(degree[row]), MODULUS-2) }
			identity := i64(0)
			if row == column { identity = 1 }
			reduced[row][column] = norm(identity-transition)
		}
		for target := 0; target < n; target += 1 {
			correction := i64(0)
			if row == target { correction = reciprocal[target] }
			reduced[row][n-1+target] = norm(1-correction)
		}
	}
	if !eliminate(&reduced, n-1, n) { return -1 }
	y: [MAX_N][MAX_N]i64
	for row := 0; row < n-1; row += 1 { for target := 0; target < n; target += 1 { y[row][target] = norm(reduced[row][n-1+target]) } }
	for source := 0; source < n; source += 1 {
		for target := 0; target < n; target += 1 {
			store_i64_le(output, 8*(source*n+target), norm(y[source][target]-y[target][target]))
		}
	}
	return i64(output_bytes)
}
